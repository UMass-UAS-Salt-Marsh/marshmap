#' Helper to rasterize transects for one dataset (train/val/test)
#' 
#' @param transects sf object of transects for this dataset
#' @param patch_ext terra extent for current patch
#' @param template terra raster template
#' @param class_mapping Named vector for class remapping
#' @returns List with mask_array, label_array, n_pixels, classes_string (or NULL if no data)
#' @keywords internal


rasterize_transects_for_patch <- function(transects, patch_ext, template, class_mapping) {
   
   
   # Crop transects to patch
   transects_patch <- tryCatch({
      suppressWarnings(st_crop(transects, patch_ext))
   }, error = function(e) NULL)
   
   # Check for valid geometry
   if (!is.null(transects_patch) && nrow(transects_patch) > 0) {
      # Filter out lines created by edge clipping
      geom_types <- st_geometry_type(transects_patch)
      if (any(geom_types != "POLYGON" & geom_types != "MULTIPOLYGON")) {
         transects_patch <- transects_patch[
            geom_types %in% c("POLYGON", "MULTIPOLYGON"), 
         ]
      }
      
      # If nothing left after filtering, return NULL
      if (nrow(transects_patch) == 0) {
         return(NULL)
      }
   } else {
      return(NULL)
   }
   
   # Rasterize
   label_rast <- rasterize(transects_patch, template, field = "subclass")
   label_array <- matrix(values(label_rast), nrow = nrow(label_rast), 
                         ncol = ncol(label_rast), byrow = FALSE)
   label_array <- t(label_array)
   
   # Remap classes
   label_remapped <- label_array
   for (old_class in names(class_mapping)) {
      label_remapped[label_array == as.numeric(old_class)] <- 
         class_mapping[[old_class]]
   }
   
   # Create mask
   mask_array <- ifelse(is.na(label_array), 0, 1)
   
   # Extract metadata
   n_pixels <- sum(mask_array)
   classes_string <- paste(unique(label_remapped[!is.na(label_remapped)]), collapse = ',')
   
   return(list(
      mask_array = mask_array,
      label_array = label_remapped,
      n_pixels = n_pixels,
      classes_string = classes_string
   ))
}