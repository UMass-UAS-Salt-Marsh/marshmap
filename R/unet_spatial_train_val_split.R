#' Split patches into train and validation sets spatially
#' 
#' @param patches List from unet_extract_training_patches
#' @param transects Original sf transects object
#' @param holdout Holdout set to use (uses bypoly<holdout>, classes 1 and 6). Holdout sets are
#'    created by `gather` to yield at least 20% of separate polys. There are 5 sets to choose from.
#' @returns List with train and val patch indices
#' @importFrom sf st_as_sf st_nearest_feature
#' @keywords internal


unet_spatial_train_val_split <- function(patches, transects, holdout = 1) {
   
   
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
   message('Validate patches: ', length(validate_idx))
   
   
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
