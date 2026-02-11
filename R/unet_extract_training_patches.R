#' Extract training patches with separate train and val masks
#' 
#' @param input_stack All predictors (raster)
#' @param transects Ground truth polys (sf object)
#' @param train_ids IDs of training transects
#' @param validate_ids IDs of validation transects
#' @param test_ids IDs of test transects
#' @param patch Patch size (n pixels)
#' @param overlap Proportional patch overlap (e.g., 0.75 for training, 0 for val)
#' @param classes Classes to include
#' @param class_mapping Mapping from original to 0-indexed classes
#' @returns List with patches, labels, train_masks, val_masks, test_masks, metadata
#' @importFrom sf st_union st_intersects st_as_sf st_coordinates st_crop st_buffer
#' @importFrom terra rast rasterize crop ext res crs nlyr values
#' @keywords internal


unet_extract_training_patches <- function(input_stack, transects, train_ids, validate_ids, test_ids,
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
   train_masks <- array(0, dim = c(n_patches, patch, patch))      # separate train/val/test masks
   val_masks <- array(0, dim = c(n_patches, patch, patch))
   test_masks <- array(0, dim = c(n_patches, patch, patch))
   
   
   metadata <- data.frame(
      patch_id = 1:n_patches,
      center_x = st_coordinates(patch_centers_valid)[, 1],
      center_y = st_coordinates(patch_centers_valid)[, 2],
      n_train_pixels = NA,
      n_val_pixels = NA,
      n_test_pixels = NA,
      train_classes = NA,
      val_classes = NA,
      test_classes = NA
   )
   
   
   # Split transects into train, val, and test
   train_transects <- transects[transects$poly %in% train_ids, ]
   val_transects <- transects[transects$poly %in% validate_ids, ]
   test_transects <- transects[transects$poly %in% test_ids, ]
   
   # Rasterize transects for train/val/test sets
   for (i in 1:n_patches) {
      pc <- st_coordinates(patch_centers_valid[i, ])
      patch_ext <- ext(pc[1] - patch_size_m / 2, pc[1] + patch_size_m / 2,
                       pc[2] - patch_size_m / 2, pc[2] + patch_size_m / 2)
      
      # Extract patch raster
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
      
      # Create template
      template <- rast(patch_ext, nrows = patch, ncols = patch, 
                       crs = crs(input_stack))
      
      # Process TRAIN transects
      train_result <- rasterize_transects_for_patch(train_transects, patch_ext, 
                                                    template, class_mapping)
      if (!is.null(train_result)) {
         train_masks[i, , ] <- train_result$mask_array
         metadata$n_train_pixels[i] <- train_result$n_pixels
         metadata$train_classes[i] <- train_result$classes_string
         
         # Merge labels
         if (is.na(labels[i, 1, 1])) {
            labels[i, , ] <- train_result$label_array
         } else {
            labels[i, , ][!is.na(train_result$label_array)] <- 
               train_result$label_array[!is.na(train_result$label_array)]
         }
      }
      
      # Process VAL transects
      val_result <- rasterize_transects_for_patch(val_transects, patch_ext, 
                                                  template, class_mapping)
      if (!is.null(val_result)) {
         val_masks[i, , ] <- val_result$mask_array
         metadata$n_val_pixels[i] <- val_result$n_pixels
         metadata$val_classes[i] <- val_result$classes_string
         
         # Merge labels
         if (is.na(labels[i, 1, 1])) {
            labels[i, , ] <- val_result$label_array
         } else {
            labels[i, , ][!is.na(val_result$label_array)] <- 
               val_result$label_array[!is.na(val_result$label_array)]
         }
      }
      
      # Process TEST transects
      test_result <- rasterize_transects_for_patch(test_transects, patch_ext, 
                                                   template, class_mapping)
      if (!is.null(test_result)) {
         test_masks[i, , ] <- test_result$mask_array
         metadata$n_test_pixels[i] <- test_result$n_pixels
         metadata$test_classes[i] <- test_result$classes_string
         
         # Merge labels
         if (is.na(labels[i, 1, 1])) {
            labels[i, , ] <- test_result$label_array
         } else {
            labels[i, , ][!is.na(test_result$label_array)] <- 
               test_result$label_array[!is.na(test_result$label_array)]
         }
      }
   }
   
   
   # Ensure n_train_pixels, n_val_pixels, and n_test_pixels are never NA (set to 0 if not set)
   metadata$n_train_pixels[is.na(metadata$n_train_pixels)] <- 0
   metadata$n_val_pixels[is.na(metadata$n_val_pixels)] <- 0
   metadata$n_test_pixels[is.na(metadata$n_test_pixels)] <- 0
   
   
   # Filter to patches with ANY labeled pixels
   has_train <- metadata$n_train_pixels > 0
   has_val <- metadata$n_val_pixels > 0
   has_test <- metadata$n_test_pixels > 0
   has_any <- has_train | has_val | has_test
   
   message('Total patches with labels: ', sum(has_any))
   message('  Patches with train labels: ', sum(has_train))
   message('  Patches with val labels: ', sum(has_val))
   message('  Patches with test labels: ', sum(has_test))
   message('  Patches with all three: ', sum(has_train & has_val & has_test))
   
   # Filter everything first
   patches_filtered <- patches[has_any, , , ]
   labels_filtered <- labels[has_any, , ]
   train_masks_filtered <- train_masks[has_any, , ]
   val_masks_filtered <- val_masks[has_any, , ]
   test_masks_filtered <- test_masks[has_any, , ]
   metadata_filtered <- metadata[has_any, ]
   has_train_filtered <- has_train[has_any]
   has_val_filtered <- has_val[has_any]
   has_test_filtered <- has_test[has_any]
   
   # NOW do validation checks on filtered data
   train_mask_sums <- apply(train_masks_filtered, 1, sum)
   val_mask_sums <- apply(val_masks_filtered, 1, sum)
   test_mask_sums <- apply(test_masks_filtered, 1, sum)
   
   if (any(has_train_filtered & train_mask_sums == 0)) {
      bad_patches <- which(has_train_filtered & train_mask_sums == 0)
      message('ERROR: Found ', length(bad_patches), ' patches with has_train=TRUE but zero mask pixels')
      message('Patch IDs: ', paste(metadata_filtered$patch_id[bad_patches], collapse=', '))
      stop('BUG: Some patches flagged has_train=TRUE have zero train mask pixels!')
   }
   
   if (any(has_val_filtered & val_mask_sums == 0)) {
      bad_patches <- which(has_val_filtered & val_mask_sums == 0)
      message('ERROR: Found ', length(bad_patches), ' patches with has_val=TRUE but zero mask pixels')
      message('Patch IDs: ', paste(metadata_filtered$patch_id[bad_patches], collapse=', '))
      stop('BUG: Some patches flagged has_val=TRUE have zero val mask pixels!')
   }
   
   if (any(has_test_filtered & test_mask_sums == 0)) {
      bad_patches <- which(has_test_filtered & test_mask_sums == 0)
      message('ERROR: Found ', length(bad_patches), ' patches with has_test=TRUE but zero mask pixels')
      message('Patch IDs: ', paste(metadata_filtered$patch_id[bad_patches], collapse=', '))
      stop('BUG: Some patches flagged has_test=TRUE have zero test mask pixels!')
   }
   
   
   # Return filtered data
   return(list(
      patches = patches_filtered,
      labels = labels_filtered,
      train_masks = train_masks_filtered,
      val_masks = val_masks_filtered,
      test_masks = test_masks_filtered,
      metadata = metadata_filtered,
      has_train = has_train_filtered,
      has_val = has_val_filtered,
      has_test = has_test_filtered
   ))
}
