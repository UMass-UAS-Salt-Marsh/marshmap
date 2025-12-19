#' Extract training patches that overlap with transects
#' 
#' @param input_stack SpatRaster (8 bands)
#' @param transects sf object with ground truth polygons
#' @param patch Size of patches in pixels (e.g., 256)
#' @param overlap Overlap fraction between patches (e.g., 0.5 for 50%)
#' @return List containing patches (array), labels (array), masks (array), metadata (df)


unet_extract_training_patches <- function(input_stack, transects, patch = 256, 
                                          overlap = 0.5, classes = c(3,4,5,6),
                                          class_mapping = c("3"=0, "4"=1, "5"=2, "6"=3)) {
   
   
   # Filter to target classes
   transects <- transects %>% 
      filter(Subclass %in% classes)
   
   if (nrow(transects) == 0) {
      warning("No transects with target classes found")
      return(NULL)
   }
   
   # Reproject transects to match raster if needed
   transects <- st_transform(transects, crs(input_stack))
   
   # Get raster extent and resolution
   res_x <- res(input_stack)[1]
   patch_size_m <- patch * res_x
   step_size <- patch * (1 - overlap)
   
   # Create grid of potential patch centers
   ext <- ext(input_stack)
   x_centers <- seq(ext$xmin + patch_size_m/2, ext$xmax - patch_size_m/2, 
                    by = step_size * res_x)
   y_centers <- seq(ext$ymin + patch_size_m/2, ext$ymax - patch_size_m/2, 
                    by = step_size * res_x)
   
   patch_centers <- expand.grid(x = x_centers, y = y_centers)
   patch_centers_sf <- st_as_sf(patch_centers, coords = c("x", "y"), 
                                crs = crs(input_stack))
   
   # Filter to centers that intersect transects (with buffer)
   transects_buffered <- st_buffer(transects, dist = patch_size_m / 2)
   patch_centers_valid <- patch_centers_sf[st_intersects(patch_centers_sf, 
                                                         st_union(transects_buffered), 
                                                         sparse = FALSE), ]
   
   n_patches <- nrow(patch_centers_valid)
   message("Extracting ", n_patches, " patches...")
   
   # Initialize arrays
   patches <- array(NA, dim = c(n_patches, patch, patch, nlyr(input_stack)))
   labels <- array(NA, dim = c(n_patches, patch, patch))
   masks <- array(0, dim = c(n_patches, patch, patch))
   
   metadata <- data.frame(
      patch_id = 1:n_patches,
      center_x = st_coordinates(patch_centers_valid)[, 1],
      center_y = st_coordinates(patch_centers_valid)[, 2],
      n_labeled_pixels = NA,
      classes_present = NA
   )
   
   # Extract each patch
   for (i in 1:n_patches) {
      center <- st_coordinates(patch_centers_valid[i, ])
      
      # Define patch extent
      patch_ext <- ext(center[1] - patch_size_m/2, center[1] + patch_size_m/2,
                       center[2] - patch_size_m/2, center[2] + patch_size_m/2)
      
      # Crop input stack
      patch_rast <- crop(input_stack, patch_ext)
      
      # Convert to array [H, W, C]
      patch_array <- as.array(patch_rast)
      patch_array <- aperm(patch_array, c(2, 1, 3))  # terra gives [W, H, C], need [H, W, C]
      
      # Handle edge cases where patch is smaller than expected
      actual_h <- dim(patch_array)[1]
      actual_w <- dim(patch_array)[2]
      
      if (actual_h < patch || actual_w < patch) {
         # Pad with zeros
         padded <- array(0, dim = c(patch, patch, nlyr(input_stack)))
         padded[1:actual_h, 1:actual_w, ] <- patch_array
         patch_array <- padded
      }
      
      patches[i, , , ] <- patch_array
      
      # Rasterize transects to get labels
      transects_patch <- st_crop(transects, patch_ext)
      
      if (nrow(transects_patch) > 0) {
         # Create template raster
         template <- rast(patch_ext, nrows = patch, ncols = patch, 
                          crs = crs(input_stack))
         
         # Rasterize transects - use Subclass attribute
         label_rast <- rasterize(transects_patch, template, field = "Subclass")
         label_array <- as.matrix(label_rast, wide = TRUE)
         label_array <- label_array[nrow(label_array):1, ]  # flip vertically
         
         # Remap classes (3,4,5,6 -> 0,1,2,3)
         label_array_remapped <- label_array
         for (old_class in names(class_mapping)) {
            label_array_remapped[label_array == as.numeric(old_class)] <- 
               class_mapping[[old_class]]
         }
         
         # Create mask (1 where labeled, 0 where not)
         mask_array <- ifelse(is.na(label_array), 0, 1)
         
         labels[i, , ] <- label_array_remapped
         masks[i, , ] <- mask_array
         
         # Metadata
         metadata$n_labeled_pixels[i] <- sum(mask_array)
         metadata$classes_present[i] <- paste(unique(label_array_remapped[!is.na(label_array_remapped)]), 
                                              collapse = ",")
      }
   }
   
   # Filter out patches with no labeled pixels
   valid_patches <- metadata$n_labeled_pixels > 0
   
   message("Keeping ", sum(valid_patches), " patches with labels")
   
   return(list(
      patches = patches[valid_patches, , , ],
      labels = labels[valid_patches, , ],
      masks = masks[valid_patches, , ],
      metadata = metadata[valid_patches, ]
   ))
}