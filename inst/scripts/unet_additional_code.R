1. Prediction from U-Net Models

For validation data (patches already extracted):
   
   r
# Simple R function wrapping Python prediction
predict_unet <- function(model_path, patches) {
   # Load model via reticulate
   torch <- import("torch")
   model <- torch$load(model_path)
   model$eval()  # Set to evaluation mode
   
   # Convert R array to torch tensor
   patches_tensor <- torch$from_numpy(patches)
   
   # Predict (no gradients needed)
   with(torch$no_grad(), {
      predictions <- model(patches_tensor)
   })
   
   # Convert back to R array
   preds_array <- predictions$numpy()
   
   return(preds_array)
}

For full-site mapping (sliding window over large raster):
   
   r
# Predict on full orthomosaic
predict_unet_raster <- function(model_path, input_stack, patch_size = 256, overlap = 0.5) {
   # Similar to your extract_training_patches, but:
   # - Extract patches across entire raster (not just transects)
   # - Predict each patch
   # - Stitch predictions back together
   # - Return SpatRaster
}

Training doesn't automatically validate - you'll run validation manually after each epoch or at the end.
2. Integration with Your fit Function

Option A: Separate fit_unet() initially (recommended for testing)

r
#' @export
fit_unet <- function(data_dir, site, n_epochs = 50, batch_size = 8, 
                     learning_rate = 0.001, output_dir = "models", ...) {
   
   # Load training data (numpy files you created)
   # Call Python training script via reticulate
   # Save model weights
   # Return model metadata for your database
   
   result <- list(
      model_path = "path/to/saved_model.pth",
      site = site,
      n_epochs = n_epochs,
      train_loss = loss_history,
      val_accuracy = final_val_acc,
      # ... other metadata
      model_type = "unet"
   )
   
   class(result) <- c("unet_fit", "model_fit")
   return(result)
}

Option B: Integrate into existing fit() later

Once working, add a method = "unet" argument to your existing fit() and dispatch internally.
3. Assessment with Your assess Function

What U-Net provides:
   
   Training/validation loss curves (over epochs)
Per-class metrics: Accuracy, Precision, Recall, F1, IoU
Confusion matrix on validation set
Overall accuracy, Kappa

What U-Net does NOT provide:
   
   Variable importance - CNNs don't have this in the RF sense
    Alternative: Saliency maps or Grad-CAM (shows which pixels influenced predictions) - advanced, can discuss later

Adapter for your assess function:

r
#' @export
assess.unet_fit <- function(model_obj, validation_data = NULL, ...) {
   
   # If validation data provided, generate predictions
   if (!is.null(validation_data)) {
      preds <- predict_unet(model_obj$model_path, validation_data$patches)
      labels <- validation_data$labels
      masks <- validation_data$masks
      
      # Calculate metrics only where mask = 1
      # ... compute confusion matrix, accuracy, etc.
   } else {
      # Use stored validation metrics from training
      metrics <- model_obj$val_metrics
   }
   
   # Return in format compatible with your existing assess output
   result <- list(
      confusion_matrix = conf_mat,
      overall_accuracy = acc,
      per_class_metrics = class_stats,
      variable_importance = NULL,  # or "Not applicable for U-Net"
      loss_curves = model_obj$train_loss  # Unique to neural nets
   )
   
   return(result)
}

You can reuse most of your existing assess logic - just needs predictions + labels + masks.
4. Mapping with Your map Function

Approach:
   
   Create predict_unet_raster() that takes:
   
   Trained model path
Input SpatRaster stack (8 bands)
Returns SpatRaster with class predictions

r
#' @export
map_unet <- function(model_obj, ortho_portable_name, site, output_dir, ...) {
   
   # Build input stack (like in data prep)
   input_stack <- build_input_stack(ortho_portable_name, ...)
   
   # Sliding window prediction
   pred_raster <- predict_unet_raster(
      model_path = model_obj$model_path,
      input_stack = input_stack,
      patch_size = 256,
      overlap = 0.5  # To smooth edges
   )
   
   # Save as GeoTIFF
   output_path <- file.path(output_dir, paste0(site, "_", model_obj$model_id, ".tif"))
   writeRaster(pred_raster, output_path)
   
   # Return metadata for your maps database
   return(list(
      map_path = output_path,
      model_id = model_obj$model_id,
      site = site,
      ortho = ortho_portable_name
   ))
}

This can be called from batch mode just like your existing map().
5. Database Integration

Your fit database should store:
   
   r
# Example row in fit database
fit_record <- data.frame(
   model_id = "unet_site1_20250203_001",
   model_type = "unet",
   site = "site1",
   model_path = "/path/to/model.pth",
   train_date = Sys.Date(),
   n_epochs = 50,
   val_accuracy = 0.78,
   notes = "4-class gradient model, masked loss"
)

Your maps database:
   
   r
map_record <- data.frame(
   map_id = "map_site1_20250203_001",
   model_id = "unet_site1_20250203_001",  # Link to fit database
   site = "site1",
   ortho = "ortho_mica_fall_2022_low",
   map_path = "/path/to/prediction.tif",
   created_date = Sys.Date()
)

The key difference from RF:
   
   model_path points to .pth file (PyTorch weights) instead of .rds
Need to load via reticulate, not base R

Proposed Workflow Architecture

Phase 1: Standalone functions (what we'll build first)

r
# 1. Fit model
model <- fit_unet(
  data_dir = "output/site1",
  site = "site1",
  n_epochs = 50
)

# 2. Assess on validation data
assessment <- assess_unet(
  model_path = model$model_path,
  val_data_dir = "output/site1"
)

# 3. Map full site
map_result <- map_unet(
  model_path = model$model_path,
  ortho_portable_name = "ortho_mica_fall_2022_low",
  site = "site1"
)

# 4. Add to databases (your existing functions)
add_to_fit_database(model)
add_to_map_database(map_result)

Phase 2: Integrate into existing framework

Once working, modify your existing fit(), assess(), map() to dispatch to *_unet() variants when method = "unet".
Key Design Decisions

1. Where does Python code live?

Option A: Embedded in R functions via reticulate::py_run_string()

r
fit_unet <- function(...) {
  reticulate::py_run_string("
    import torch
    # ... training code
  ")
}

Option B: Separate Python script called from R

r
fit_unet <- function(...) {
  reticulate::source_python("train_unet.py")
  # Calls functions defined in that script
}

Option C: Mix - complex training in .py file, simple prediction embedded