#' Extract training patches with separate train and val masks
#' 
#' @param input_stack All predictors (raster)
#' @param transects Ground truth polys (sf object)
#' @param train_ids IDs of training transects
#' @param validate_ids IDs of validation transects
#' @param patch Patch size (n pixels)
#' @param overlap Proportional patch overlap (e.g., 0.75 for training, 0 for val)
#' @param classes Classes to include
#' @param class_mapping Mapping from original to 0-indexed classes
#' @returns List with patches, labels, train_masks, val_masks, metadata
#' @importFrom sf st_union st_intersects st_as_sf st_coordinates st_crop st_buffer
#' @importFrom terra rast rasterize crop ext res crs nlyr values
#' @keywords internal


unet_extract_training_patches <- function(input_stack, transects, train_ids, validate_ids,
                                          patch = 256, overlap = 0.5, 
                                          classes,
                                          class_mapping) {
   
   
   ext <- ext(input_stack)
   rez <- res(input_stack)[1]
   patch_size_m <- patch * rez
   step_size <- patch * (1 - overlap)
   
   
   # Grid of potential patch centers
   x_centers <- seq(ext$xmin + patch_size_m / 2, ext$xmax - patch_size_m / 2,
                    by = step_size * rez)
   y_centers <- seq(ext$ymin + patch_size_m / 2, ext$ymax - patch_size_m / 2, 
                    by = step_size * rez)
   
   patch_centers <- expand.grid(x = x_centers, y = y_centers)
   patch_centers_sf <- st_as_sf(patch_centers, coords = c('x', 'y'), 
                                crs = crs(input_stack))
   
   
   # Filter to patches that intersect ANY transect
   transects_buffered <- st_buffer(transects, dist = patch_size_m / 2)
   patch_centers_valid <- patch_centers_sf[st_intersects(patch_centers_sf, 
                                                         st_union(transects_buffered), 
                                                         sparse = FALSE), ]
   
   n_patches <- nrow(patch_centers_valid)
   message('Extracting ', n_patches, ' patches...')
   
   
   # Initialize arrays
   patches <- array(NA, dim = c(n_patches, patch, patch, nlyr(input_stack)))
   labels <- array(NA, dim = c(n_patches, patch, patch))
   train_masks <- array(0, dim = c(n_patches, patch, patch))   # NEW: separate masks
   val_masks <- array(0, dim = c(n_patches, patch, patch))     # NEW: separate masks
   
   metadata <- data.frame(
      patch_id = 1:n_patches,
      center_x = st_coordinates(patch_centers_valid)[, 1],
      center_y = st_coordinates(patch_centers_valid)[, 2],
      n_train_pixels = NA,    # NEW
      n_val_pixels = NA,      # NEW
      train_classes = NA,     # NEW
      val_classes = NA        # NEW
   )
   
   
   # Split transects into train and val
   train_transects <- transects[transects$poly %in% train_ids, ]
   val_transects <- transects[transects$poly %in% validate_ids, ]
   
   for (i in 1:n_patches) {
      pc <- st_coordinates(patch_centers_valid[i, ])
      patch_ext <- ext(pc[1] - patch_size_m / 2, pc[1] + patch_size_m / 2,
                       pc[2] - patch_size_m / 2, pc[2] + patch_size_m / 2)
      
      
      # Crop input stack
      patch_rast <- crop(input_stack, patch_ext)
      patch_array <- array(values(patch_rast), dim = c(nrow(patch_rast), 
                                                       ncol(patch_rast), nlyr(patch_rast)))
      
      
      # Handle edge cases
      actual_h <- dim(patch_array)[1]
      actual_w <- dim(patch_array)[2]
      
      if (actual_h < patch || actual_w < patch) {
         padded <- array(0, dim = c(patch, patch, nlyr(input_stack)))
         padded[1:actual_h, 1:actual_w, ] <- patch_array
         patch_array <- padded
      }
      
      patches[i, , , ] <- patch_array
      
      
      # Create template raster for this patch
      template <- rast(patch_ext, nrows = patch, ncols = patch, 
                       crs = crs(input_stack))
      
      
      # Rasterize TRAIN transects
      train_transects_patch <- tryCatch({
         suppressWarnings(st_crop(train_transects, patch_ext))
      }, error = function(e) NULL)
      
      if (!is.null(train_transects_patch) && nrow(train_transects_patch) > 0) {
         train_label_rast <- rasterize(train_transects_patch, template, field = "subclass")
         train_label_array <- matrix(values(train_label_rast), nrow = nrow(train_label_rast), 
                                     ncol = ncol(train_label_rast), byrow = FALSE)
         train_label_array <- t(train_label_array)
         
         # Remap classes
         train_label_remapped <- train_label_array
         for (old_class in names(class_mapping)) {
            train_label_remapped[train_label_array == as.numeric(old_class)] <- 
               class_mapping[[old_class]]
         }
         
         # Train mask
         train_mask_array <- ifelse(is.na(train_label_array), 0, 1)
         train_masks[i, , ] <- train_mask_array
         
         metadata$n_train_pixels[i] <- sum(train_mask_array)
         metadata$train_classes[i] <- paste(unique(train_label_remapped[!is.na(train_label_remapped)]), 
                                            collapse = ',')
         
         # Store labels (will be combined with val labels)
         if (is.na(labels[i, 1, 1])) {  # First time setting labels
            labels[i, , ] <- train_label_remapped
         } else {  # Merge with existing
            labels[i, , ][!is.na(train_label_remapped)] <- train_label_remapped[!is.na(train_label_remapped)]
         }
      }
      
      # Rasterize VAL transects
      val_transects_patch <- tryCatch({
         suppressWarnings(st_crop(val_transects, patch_ext))
      }, error = function(e) NULL)
      
      if (!is.null(val_transects_patch) && nrow(val_transects_patch) > 0) {
         val_label_rast <- rasterize(val_transects_patch, template, field = "subclass")
         val_label_array <- matrix(values(val_label_rast), nrow = nrow(val_label_rast), 
                                   ncol = ncol(val_label_rast), byrow = FALSE)
         val_label_array <- t(val_label_array)
         
         # Remap classes
         val_label_remapped <- val_label_array
         for (old_class in names(class_mapping)) {
            val_label_remapped[val_label_array == as.numeric(old_class)] <- 
               class_mapping[[old_class]]
         }
         
         # Val mask
         val_mask_array <- ifelse(is.na(val_label_array), 0, 1)
         val_masks[i, , ] <- val_mask_array
         
         metadata$n_val_pixels[i] <- sum(val_mask_array)
         metadata$val_classes[i] <- paste(unique(val_label_remapped[!is.na(val_label_remapped)]), 
                                          collapse = ',')
         
         # Store labels (merge with train labels)
         if (is.na(labels[i, 1, 1])) {  # First time setting labels
            labels[i, , ] <- val_label_remapped
         } else {  # Merge with existing
            labels[i, , ][!is.na(val_label_remapped)] <- val_label_remapped[!is.na(val_label_remapped)]
         }
      }
   }
   
   
   # Filter to patches with ANY labeled pixels
   has_train <- metadata$n_train_pixels > 0
   has_val <- metadata$n_val_pixels > 0
   has_any <- has_train | has_val
   has_any[is.na(has_any)] <- FALSE
   
   message('Total patches with labels: ', sum(has_any))
   message('  Patches with train labels: ', sum(has_train, na.rm = TRUE))
   message('  Patches with val labels: ', sum(has_val, na.rm = TRUE))
   message('  Patches with both: ', sum(has_train & has_val, na.rm = TRUE))
   
   
   # Return ALL patches, but with separate train/val masks
   return(list(
      patches = patches[has_any, , , ],
      labels = labels[has_any, , ],
      train_masks = train_masks[has_any, , ],
      val_masks = val_masks[has_any, , ],
      metadata = metadata[has_any, ],
      has_train = has_train[has_any],   # Boolean vector
      has_val = has_val[has_any]        # Boolean vector
   ))
}
