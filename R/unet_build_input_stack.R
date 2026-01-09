#' Build input stack for a given portable ortho name
#' 
#' @param fpath Path to flights directory
#' @param config Named `config` list, including 
#'  - `config$fpath` Path to flights
#'  - `config$orthos` Vector of orthophoto names (typically a 5-band Mica, NDVI, NDRE, and a matching DEM)
#'  - `config$type` Vector of ortho type corresponding to `orthos`
#'  - `config$bands` Number of bands in each ortho
#' @returns SpatRaster with all bands (typically Blue, Green, Red, NIR, RedEdge, NDVI, NDRE, DEM)
#' @importFrom terra rast values global quantile clamp


unet_build_input_stack <- function(config) {
   
   
   # Helper: Normalize raster to 0-1
   unet_normalize_band <- function(r, lower = 0.02, upper = 0.98) {
      vals <- values(r, na.rm = TRUE)
      q_lower <- quantile(vals, lower, na.rm = TRUE)
      q_upper <- quantile(vals, upper, na.rm = TRUE)
      r_norm <- (r - q_lower) / (q_upper - q_lower)
      clamp(r_norm, lower = 0, upper = 1, values = TRUE)
   }
   
   
   # Helper: Standardize raster (mean=0, sd=1)
   unet_standardize_band <- function(r) {
      r_mean <- global(r, 'mean', na.rm = TRUE)[[1]]
      r_sd <- global(r, 'sd', na.rm = TRUE)[[1]]
      (r - r_mean) / (r_sd + 1e-8)
   }
   
   
   
   z <- NULL
   for(i in seq_along(config$orthos)) {                                       # for each ortho,
      x <- rast(file.path(config$fpath, config$orthos[i]))                    #    read it
      switch(config$type[i],
             'image' = {                                                      #    if it's an image,
                q <- NULL
                for(j in seq_len(config$bands[i]))  
                   q <- c(q, unet_normalize_band(x[[j]]))                     #       normalize each band
                if(config$bands[i] == 3)                                      #       and name bands
                   names(q) <- c('red', 'green', 'blue')
                else
                   names(q) <- c('blue', 'green', 'red',  'nir', 'red_edge')
                z <- c(z, q)
             },                
             'ndvi' = z <- c(z, ndvi = x),                                    #    NDVI and NDRE are fine as-is
             'ndre' = z <- c(z, ndre = x),
             'dem' = z <- c(z, dem = unet_standardize_band(x))                #    if it's a DEM, standardize it
      )
   }
   
   z <- rast(z)                                                               # convert the list of rasters to a raster stack
   z
}