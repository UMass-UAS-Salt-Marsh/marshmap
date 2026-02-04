#' Build input stack for a given portable ortho name
#' 
#' @param fpath Path to flights directory
#' @param config Named `config` list, including 
#'  - `config$fpath` Path to flights
#'  - `config$orthos` Vector of orthophoto names (typically a 5-band Mica, NDVI, NDRE, and a matching DEM)
#'  - `config$type` Vector of ortho type corresponding to `orthos`
#'  - `config$bands` Number of bands in each ortho
#' @returns SpatRaster with all bands (typically Blue, Green, Red, NIR, RedEdge, NDVI, NDRE, DEM)
#' @keywords internal


unet_build_input_stack <- function(config) {
   
   
   # Helper: Normalize raster to 0-1 by quantiles
   unet_normalize_band <- function(r, lower = 0.02, upper = 0.98) {
      vals <- values(r, na.rm = TRUE)
      q_lower <- quantile(vals, lower, na.rm = TRUE)
      q_upper <- quantile(vals, upper, na.rm = TRUE)
      
      if (q_upper - q_lower < 1e-10) {
         warning("Band has no variation, setting to 0.5")
         r_norm <- r * 0 + 0.5                                 # Constant 0.5
      } 
      else {
         r_norm <- (r - q_lower) / (q_upper - q_lower)
      }
      clamp(r_norm, lower = 0, upper = 1, values = TRUE)
   }
   
   
   # Helper: Standardize raster (mean=0, sd=1)
   unet_standardize_band <- function(r) {
      r_mean <- global(r, 'mean', na.rm = TRUE)[[1]]
      r_sd <- global(r, 'sd', na.rm = TRUE)[[1]]
      (r - r_mean) / (r_sd + 1e-8)
   }
   
   
   # Helper: Range rescale
   unet_range_rescale_band <- function(r) {
      r_min <- global(r, 'min', na.rm = TRUE)[[1]]
      r_max <- global(r, 'max', na.rm = TRUE)[[1]]
      
      # Handle constant bands
      if (abs(r_max - r_min) < 1e-10) {
         return(r * 0 + 0.5)
      }
      
      r_norm <- (r - r_min) / (r_max - r_min)
      return(r_norm)
   }
   
   
   z <- NULL
   for(i in seq_along(config$orthos)) {                                       # for each ortho,
      x <- rast(file.path(config$fpath, config$orthos[i]))                    #    read it
      
      message('Original raster checks for ', 
              config$orthos[i], ' (', nlyr(x), ' layers):')                   #    check each band
      
      for (j in 1:nlyr(x)) {
         band <- x[[j]]
         vals <- values(band, na.rm = TRUE)
         message(sprintf('  Band %d: NA=%d, range=[%.4f, %.4f]',
                         j, sum(is.na(values(band))), min(vals), max(vals)))
      }
      
      
      switch(config$type[i],
             'image' = {                                                      #    if it's an image,
                q <- NULL
                for(j in seq_len(config$bands[i]))  
                   q <- c(q, unet_range_rescale_band(x[[j]]))                 #       range-rescale each band
                if(config$bands[i] == 3)                                      #       and name bands
                   names(q) <- c('red', 'green', 'blue')
                else
                   names(q) <- c('blue', 'green', 'red',  'nir', 'red_edge')
                z <- c(z, q)
             },                
             'ndvi' = z <- c(z, ndvi = unet_range_rescale_band(x)),           #    I'm now range-rescaling everything
             'ndre' = z <- c(z, ndre = unet_range_rescale_band(x)),
             'dem' = z <- c(z, dem = unet_range_rescale_band(x))
      )
   }
   
   z <- rast(z)                                                               # convert the list of rasters to a raster stack
   
   
   ###  ********************************** TEMPORARY CODE **********************************
   message('Reprojecting...   [this is temporary, pending reprojection change in gather]')
   z <- project(z, 'epsg:26986')                                     
   message('Done projecting')
   ###  ************************************************************************************
   
   
   z
}