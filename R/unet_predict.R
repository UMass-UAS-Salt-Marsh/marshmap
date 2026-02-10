#' Predict with trained U-Net model
#'
#' @param model_path Path to trained model (.pth file)
#' @param data_dir Directory containing test numpy files
#' @param site Site name (e.g., 'rr')
#' @param dataset Which dataset to predict on ('test' or 'validate')
#' @param num_classes Number of classes
#' @param in_channels Number of input channels
#' @param class_mapping Named vector mapping original to internal classes
#' @returns List with predictions, labels, masks, and probabilities
#' @keywords internal

unet_predict <- function(model_path, data_dir, site, dataset = 'test',
                         num_classes = 4, in_channels = 8,
                         class_mapping = c('3'=0, '4'=1, '5'=2, '6'=3)) {
   
   # Check Python environment
   if (!reticulate::py_module_available('torch')) {
      stop('PyTorch not found. Check your Python environment.')
   }
   
   # Source Python script
   python_script <- system.file('python', 'predict_unet.py', package = 'marshmap')
   if (!file.exists(python_script)) {
      stop('predict_unet.py not found in inst/python/')
   }
   
   reticulate::source_python(python_script)
   
   # Get original classes from mapping
   original_classes <- as.integer(names(class_mapping))
   
   # Call Python prediction function
   results <- predict_unet(
      model_path = model_path,
      data_dir = data_dir,
      site = site,
      num_classes = num_classes,
      in_channels = in_channels,
      dataset = dataset,
      original_classes = original_classes
   )
   
   # Convert to R format
   # Flatten to vectors for easier confusion matrix creation
   labeled_idx <- results$masks == 1
   
   predictions_labeled <- results$predictions[labeled_idx]
   labels_labeled <- results$labels[labeled_idx]
   
   # Map back to original classes
   pred_original <- original_classes[predictions_labeled + 1]  # +1 for R indexing
   label_original <- original_classes[labels_labeled + 1]
   
   # Remove any that are still 255 (shouldn't happen but just in case)
   valid <- label_original %in% original_classes
   pred_original <- pred_original[valid]
   label_original <- label_original[valid]
   
   message('\nPrediction complete!')
   message('  Total labeled pixels: ', length(label_original))
   message('  Overall CCR: ', round(100 * mean(pred_original == label_original), 2), '%')
   
   # Return as factors for caret::confusionMatrix
   list(
      predictions = factor(pred_original, levels = original_classes),
      labels = factor(label_original, levels = original_classes),
      predictions_array = results$predictions,  # Full arrays if needed
      labels_array = results$labels,
      masks_array = results$masks,
      probabilities = results$probabilities
   )
}


#' Create confusion matrix from U-Net predictions
#'
#' @param pred_results Results from unet_predict()
#' @returns confusionMatrix object from caret
#' @importFrom caret confusionMatrix
#' @keywords internal

unet_confusion_matrix <- function(pred_results) {
   
   if (!requireNamespace('caret', quietly = TRUE)) {
      stop('caret package required. Install with: install.packages("caret")')
   }
   
   cm <- caret::confusionMatrix(
      data = pred_results$predictions,
      reference = pred_results$labels
   )
   
   return(cm)
}
