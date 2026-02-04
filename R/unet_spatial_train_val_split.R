#' Split patches into train and validation sets spatially
#' 
#' @param patches List from unet_extract_training_patches
#' @param transects Original sf transects object
#' @param holdout Holdout set to use (uses bypoly<holdout>, classes 1 and 6). Holdout sets are
#'    created by `gather` to yield at least 20% of separate polys. There are 5 sets to choose from.
#' @param patch_size Size of patches in cells
#' @param cell_width Width of cell (m)
#' @returns List with train and val patch indices
#' @importFrom sf st_crs st_as_sf st_nearest_feature
#' @keywords internal


unet_spatial_train_val_split <- function(patches, transects, holdout, patch_size, cell_width) {
   
   
   set <- transects[[paste0('bypoly', sprintf('%02d', holdout))]] %in% c(1, 6)      # holdout set
   validate_ids <- transects$poly[set]                                              # validation poly ids
   train_ids <- transects$poly[!set]                                                # training poly ids
   
   
   # Assign patches to train/val based on which transect they overlap most
   patch_centers <- st_as_sf(patches$metadata, 
                             coords = c('center_x', 'center_y'),
                             crs = st_crs(transects))
   
   
   nearest_transect <- st_nearest_feature(patch_centers, transects)                 # nearest transect to center of each patch
   patch_transect_ids <- transects$poly[nearest_transect]
   
   train_idx <- which(patch_transect_ids %in% train_ids)
   validate_idx <- which(patch_transect_ids %in% validate_ids)
   
   message('Train patches: ', length(train_idx))
   message('Preliminary validate patches: ', length(validate_idx))
   
   
   # Throw out overlapping validation patches here
   train_centers <- patches$metadata[train_idx, c('center_x', 'center_y')]           # Get centers for train and validate patches
   val_centers <- patches$metadata[validate_idx, c('center_x', 'center_y')]
   
   # Calculate minimum safe distance (2x patch radius to ensure no overlap)
   patch_size_m <- patch_size * cell_width                                          # 256 pixels at 8cm resolution (or whatever it actually is)
   min_distance <- patch_size_m * sqrt(2)                                           # length of diagonal - this is our patch separation
   
   # Check each val patch against all train patches
   keep_val <- rep(TRUE, length(validate_idx))
   
   for (i in seq_along(validate_idx)) {
      distances <- sqrt((val_centers$center_x[i] - train_centers$center_x)^2 + 
                           (val_centers$center_y[i] - train_centers$center_y)^2)
      
      if (any(distances < min_distance)) {
         keep_val[i] <- FALSE
      }
   }
   
   
   # Update validate_idx to only non-overlapping patches
   validate_idx <- validate_idx[keep_val]
   
   message('Removed ', sum(!keep_val), ' overlapping validate patches')
   message('Final validate patches: ', length(validate_idx))
   
   
   train_classes <- unlist(strsplit(patches$metadata$classes_present[train_idx], ','))
   val_classes <- unlist(strsplit(patches$metadata$classes_present[validate_idx], ','))
   
   message('Train class distribution:')
   print(table(train_classes))
   message('Validate class distribution:')
   print(table(val_classes))
   
   
   return(list(
      train_idx = train_idx,
      validate_idx = validate_idx,
      train_ids = train_ids,
      validate_ids = validate_ids
   ))
}



