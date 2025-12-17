#' Build input stack for a given portable ortho name
#' 
#' @param fpath Path to flights directory
#' @param orthos Vector of orthophoto names (typically a 5-band Mica, NDVI, NDRE, and a matching DEM)
#' @return SpatRaster with all bands (typically RGB, NIR, RedEdge, NDVI, NDRE, DEM)

# Notes:
# [ ] May want to normalize and standardize in derive so they only happen once

unet_build_input_stack <- function(fpath, config) {
   ###function(portable_name, ortho_dir, ortho_lookup, dem_lookup) {

   
   
   # Helper: Normalize raster to 0-1
   unet_normalize_band <- function(r, method = 'percentile', lower = 0.02, upper = 0.98) {
      if (method == 'percentile') {
         vals <- values(r, na.rm = TRUE)
         q_lower <- quantile(vals, lower, na.rm = TRUE)
         q_upper <- quantile(vals, upper, na.rm = TRUE)
         r_norm <- (r - q_lower) / (q_upper - q_lower)
      } else if (method == 'minmax') {
         r_norm <- (r - global(r, 'min', na.rm = TRUE)[[1]]) / 
            (global(r, 'max', na.rm = TRUE)[[1]] - global(r, 'min', na.rm = TRUE)[[1]])
      }
      clamp(r_norm, lower = 0, upper = 1, values = TRUE)
   }
   

   # Helper: Standardize raster (mean=0, sd=1)
   unet_standardize_band <- function(r) {
      r_mean <- global(r, 'mean', na.rm = TRUE)[[1]]
      r_sd <- global(r, 'sd', na.rm = TRUE)[[1]]
      (r - r_mean) / (r_sd + 1e-8)
   }
   
   
   
   
      
   # Get actual filename
   multispectral_file <- file.path(ortho_dir, ortho_lookup[[portable_name]])
   dem_file <- file.path(ortho_dir, dem_lookup[[portable_name]])
   
   # Load multispectral (assuming B-G-R-RedEdge-NIR order for 5-band)
   ms <- rast(multispectral_file)
   n_bands <- nlyr(ms)
   
   if (n_bands == 3) {
      # RGB only
      blue <- ms[[1]]
      green <- ms[[2]]
      red <- ms[[3]]
      nir <- NULL
      red_edge <- NULL
      message('Warning: RGB only, no NIR/RedEdge for ', portable_name)
      
   } else if (n_bands == 5) {
      # Full multispectral: B-G-R-RedEdge-NIR
      blue <- ms[[1]]
      green <- ms[[2]]
      red <- ms[[3]]
      red_edge <- ms[[4]]
      nir <- ms[[5]]
   } else {
      stop('Unexpected number of bands: ', n_bands)
   }
   
   # Load DEM
   dem <- rast(dem_file)
   
   # Normalize spectral bands to 0-1
   blue_norm <- unet_normalize_band(blue)
   green_norm <- unet_normalize_band(green)
   red_norm <- unet_normalize_band(red)
   
   if (!is.null(nir)) {
      nir_norm <- unet_normalize_band(nir)
      red_edge_norm <- unet_normalize_band(red_edge)
      
      # Calculate indices
      ndvi <- unet_calc_ndvi(nir, red)
      ndre <- unet_calc_ndre(nir, red_edge)
      
      # Clamp indices to reasonable range
      ndvi <- clamp(ndvi, lower = -1, upper = 1, values = TRUE)
      ndre <- clamp(ndre, lower = -1, upper = 1, values = TRUE)
      
      # Rescale indices from [-1,1] to [0,1] for consistency
      ndvi <- (ndvi + 1) / 2
      ndre <- (ndre + 1) / 2
      
   } else {
      # No NIR/RedEdge - use placeholders (zeros) or handle differently
      nir_norm <- blue_norm * 0
      red_edge_norm <- blue_norm * 0
      ndvi <- blue_norm * 0
      ndre <- blue_norm * 0
      message('Warning: Using zero placeholders for missing NIR/RedEdge')
   }
   
   # Standardize DEM
   dem_std <- unet_standardize_band_band(dem)
   
   # Stack all layers
   input_stack <- c(red_norm, green_norm, blue_norm, 
                    nir_norm, red_edge_norm, 
                    ndvi, ndre, dem_std)
   
   names(input_stack) <- c('red', 'green', 'blue', 'nir', 'red_edge', 
                           'ndvi', 'ndre', 'dem')
   
   return(input_stack)
}