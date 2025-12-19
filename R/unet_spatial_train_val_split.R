#' Split patches into train and validation sets spatially
#' 
#' @param patch_data List from unet_extract_training_patches
#' @param transects Original sf transects object
#' @param holdout Fraction for validation (e.g., 0.2)
#' @param seed Random seed
#' @return List with train and val patch indices


unet_spatial_train_val_split <- function(patch_data, transects, holdout = 0.2, seed = 42) {
   
   
   set.seed(seed)
   
   # Get unique transect IDs (assuming they have an ID field, or use row number)
   if (!"transect_id" %in% names(transects)) {
      transects$transect_id <- 1:nrow(transects)
   }
   
   n_transects <- nrow(transects)
   n_val <- ceiling(n_transects * holdout)
   
   val_transect_ids <- sample(transects$transect_id, n_val)
   train_transect_ids <- setdiff(transects$transect_id, val_transect_ids)
   
   # Assign patches to train/val based on which transect they overlap most
   # (This is approximate - could be refined by checking actual overlap)
   
   # Simple approach: use spatial proximity
   patch_centers <- st_as_sf(patch_data$metadata, 
                             coords = c("center_x", "center_y"),
                             crs = st_crs(transects))
   
   # Find nearest transect for each patch
   nearest_transect <- st_nearest_feature(patch_centers, transects)
   patch_transect_ids <- transects$transect_id[nearest_transect]
   
   train_idx <- which(patch_transect_ids %in% train_transect_ids)
   val_idx <- which(patch_transect_ids %in% val_transect_ids)
   
   message("Train patches: ", length(train_idx))
   message("Val patches: ", length(val_idx))
   
   # Check class distribution
   train_classes <- unlist(strsplit(patch_data$metadata$classes_present[train_idx], ","))
   val_classes <- unlist(strsplit(patch_data$metadata$classes_present[val_idx], ","))
   
   message("Train class distribution: ", paste(table(train_classes), collapse = ", "))
   message("Val class distribution: ", paste(table(val_classes), collapse = ", "))
   
   return(list(
      train_idx = train_idx,
      val_idx = val_idx,
      train_transect_ids = train_transect_ids,
      val_transect_ids = val_transect_ids
   ))
}