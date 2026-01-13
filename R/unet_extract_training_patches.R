#' Extract training patches that overlap with transects
#' 
#' @param input_stack All predictors (raster)
#' @param transects Ground truth polys (sf object)
#' @param patch Patch size (n pixels)
#' @param overlap Proportional patch overlap (e.g., 0.5 for 50%)
#' @returns List of patches (array), labels (array), masks (array), metadata (df)
#' @importFrom terra ext res rast rasterize crs
#' @importFrom sf st_as_sf st_buffer st_intersects st_coordinates st_crop
#' @keywords internal


unet_extract_training_patches <- function(input_stack, transects, patch = 256, 
                                          overlap = 0.5, classes = c(3,4,5,6),
                                          class_mapping = c('3'=0, '4'=1, '5'=2, '6'=3)) {
   
   
   ext <- ext(input_stack)                                                                # raster extent, resolution, etc.
   rez <- res(input_stack)[1]
   patch_size_m <- patch * rez
   step_size <- patch * (1 - overlap)
   
   
   x_centers <- seq(ext$xmin + patch_size_m / 2, ext$xmax - patch_size_m / 2,             # make grid of potential patch centers
                    by = step_size * rez)
   y_centers <- seq(ext$ymin + patch_size_m / 2, ext$ymax - patch_size_m / 2, 
                    by = step_size * rez)
   
   patch_centers <- expand.grid(x = x_centers, y = y_centers)
   patch_centers_sf <- st_as_sf(patch_centers, coords = c('x', 'y'), 
                                crs = crs(input_stack))                                   # point sf of candidate patch centers
   
   
   transects_buffered <- st_buffer(transects, dist = patch_size_m / 2)
   patch_centers_valid <- patch_centers_sf[st_intersects(patch_centers_sf, 
                                                         st_union(transects_buffered), 
                                                         sparse = FALSE), ]               # filter to patch centers that intersect buffered transects
   
   n_patches <- nrow(patch_centers_valid)
   message('Extracting ', n_patches, ' patches...')
   
   
   patches <- array(NA, dim = c(n_patches, patch, patch, nlyr(input_stack)))              # initialize arrays
   labels <- array(NA, dim = c(n_patches, patch, patch))
   masks <- array(0, dim = c(n_patches, patch, patch))
   
   metadata <- data.frame(
      patch_id = 1:n_patches,
      center_x = st_coordinates(patch_centers_valid)[, 1],
      center_y = st_coordinates(patch_centers_valid)[, 2],
      n_labeled_pixels = NA,
      classes_present = NA
   )
   
   
   for (i in 1:n_patches) {                                                               # for each patch,
      pc <- st_coordinates(patch_centers_valid[i, ])
      patch_ext <- ext(pc[1] - patch_size_m / 2, pc[1] + patch_size_m / 2,
                       pc[2] - patch_size_m / 2, pc[2] + patch_size_m / 2)                #    patch extent
      
      
      patch_rast <- crop(input_stack, patch_ext)                                          #    crop input stack
      patch_array <- array(values(patch_rast), dim = c(nrow(patch_rast), 
                           ncol(patch_rast), nlyr(patch_rast)))                           #    convert to array of rows, cols, bands
      
      
      
      
      actual_h <- dim(patch_array)[1]                                                     #    handle edge cases where patch is smaller than expected
      actual_w <- dim(patch_array)[2]
      
      if (actual_h < patch || actual_w < patch) {                                         #    pad with zeros
         padded <- array(0, dim = c(patch, patch, nlyr(input_stack)))
         padded[1:actual_h, 1:actual_w, ] <- patch_array
         patch_array <- padded
      }
      
      patches[i, , , ] <- patch_array
      
      
      transects_patch <- suppressWarnings(st_crop(transects, patch_ext))                  #    rasterize transects to get labels
      
      if (nrow(transects_patch) > 0) {                                                    #    if patch has data,
         template <- rast(patch_ext, nrows = patch, ncols = patch, 
                          crs = crs(input_stack))                                         #       create template raster
         label_rast <- rasterize(transects_patch, template, field = "subclass")
         
         label_array <- matrix(values(label_rast), nrow = nrow(label_rast), 
                               ncol = ncol(label_rast), byrow = FALSE)                    #       convert to matrix [H, W]
         
         label_array <- t(label_array)                                                    #       transpose from terra's column-major to row-major
         
        
         label_array_remapped <- label_array                                              #    remap classes
         for (old_class in names(class_mapping)) {
            label_array_remapped[label_array == as.numeric(old_class)] <- 
               class_mapping[[old_class]]
         }
         
         
         mask_array <- ifelse(is.na(label_array), 0, 1)                                   #    mask (1 where labeled, 0 where not)
         labels[i, , ] <- label_array_remapped
         masks[i, , ] <- mask_array
         
         metadata$n_labeled_pixels[i] <- sum(mask_array)
         metadata$classes_present[i] <- paste(unique(label_array_remapped[!is.na(label_array_remapped)]), 
                                              collapse = ',')
      }
   }
   
   
   valid_patches <- metadata$n_labeled_pixels > 0                                         #    drop patches with no labeled pixels
   message('Keeping ', sum(valid_patches), ' patches with labels')
   
   return(list(
      patches = patches[valid_patches, , , ],
      labels = labels[valid_patches, , ],
      masks = masks[valid_patches, , ],
      metadata = metadata[valid_patches, ]
   ))
}