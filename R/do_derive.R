#' Create derived variables such as NDVI and NDRE
#'
#' @param site One or more site names, using 3 letter abbreviation. If running in batch mode, each 
#'    named site will be run in a separate job.
#' @param pattern1 File names, portable names, regex matching either, or search names
#'    selecting source for derived variables. See Image naming in
#'    [README](https://github.com/UMass-UAS-Salt-Marsh/marshmap/blob/main/README.md) 
#'    for details. See details.
#' @param pattern2 A second pattern or vector of layer names, used for bivariate metrics. See details.
#' @param metrics A list of metrics to apply. Univariate metrics include:
#' \describe{
#'    \item{NDVI}{Normalized difference vegetation index, `(NIR - red) / (NIR + red)`, an index of biomass}
#'    \item{NDWIg}{Normalized difference water index (green, commonly known as McFeeter's `NDWI`), `(green - NIR) / (green + NIR)`,
#'       primarily helps distinguish waterbodies}
#'    \item{NDRE}{Normalized difference red edge index, `(NIR - RE) / (NIR + RE)`, an index of the
#'       amount of chlorophyll in a plant}
#'    \item{mean}{mean of each band in a window, size defined by `window`}
#'    \item{sd}{standard deviation of each band in a window, size defined by `window`}
#'    \item{NDVImean}{mean of NDVI in a window, size defined by `window`}
#'    \item{NDVIsd}{standard deviation of NDVI in a window, size defined by `window`}
#'    Bivariate metrics include:
#'    \item{NDWIswir}{Normalized difference water index (SWIR, commonly known as Gao's `NDWI`), `(NIR - SWIR) / (NIR + SWIR)`,
#'       an index of water content in leaves; requires a Mica layer for `pattern1`, and a matched
#'       SWIR layer for `pattern2`}
#'    \item{delta}{The difference between `pattern1` and `pattern2`, may be useful for taking a 
#'    difference between late-season and early-season DEMs to represent vegetation canopy height}
#' }
#' @param window Window size for `mean`, `sd`, `NDVImean`, and `NDVIsd`, in cells; windows are square, so just specify
#'    a single number. Bonus points if you remember to make it odd.
#' @param cache If TRUE, cache images for `screen`. If set to FALSE, these flights
#'    will be blank in `screen`.
#' @importFrom terra rast focal writeRaster
#' @importFrom rasterPrep assessType
#' @importFrom tools file_path_sans_ext
#' @export

# Note: I have a list of 14 indices in an email from Steve Fickas, 5 May 2025


do_derive <- function(site, pattern1 = 'mica', pattern2 = NULL, metrics = c('NDVI', 'NDRE'),
                      window = 3, cache) {
   
   
   mica <- list(
      red = 3,
      green = 2,
      blue = 1,
      re = 4,
      nir = 5
   )
   
   
   # When adding new metrics, they also need to be added to derive: in pars.yml
   if(!all(b <- metrics %in% c('NDVI', 'NDWIg', 'NDRE', 'NDVImean', 'NDVIsd', 'mean', 'sd', 'NDWIswir', 'delta')))
      stop('Unknown metrics: ', metrics[!b])
   
   
   path <- resolve_dir(the$flightsdir, tolower(site))                                     # flights directory
   
   files <- list.files(path)
   files <- files[grep('.tif$', tolower(files))]                                          # only want files ending in .tif
   files <- files
   one <- find_orthos(site, pattern1)$file                                                # match user's pattern(s) for pattern1
   one <- one[grep('__', one, invert = TRUE)]                                             # please, no derived files!
   one <- file_path_sans_ext(one)                                                         # drop .tif here; we'll add it as needed
   
   if(!is.null(pattern2)) {
      two <- find_orthos(site, pattern1)$file                                             # match user's pattern(s) for pattern2
      two <- two[grep('__', two, invert = TRUE)]                                          # please, no derived files!
      two <- file_path_sans_ext(two)                                                      # drop .tif here; we'll add it as needed
      
      if(length(pattern1) != length(pattern2))
         stop('pattern1 and pattern2 returned different numbers of files')
      
      if(any(metrics %in% c('NDVI', 'NDWIg', 'NDRE', 'mean', 'sd', 'NDVI_mean', 'NDVI_sd')))
         stop('Univariate metrics cannot be used with pattern2')
   }
   else {
      two <- ''
      if(any(metrics %in% c('NDWIswir', 'delta')))
         stop('Bivariate metrics require pattern2')
   }
   
   
   for(i in seq_along(one))
      for(j in seq_along(metrics)) {
         
         message('Calculating metric ', metrics[j], ' for ', one[i], ifelse(!is.null(pattern2), paste0(' and ', two[i]), ''), '...')
         
         x <- rast(file.path(path, paste0(one[i], '.tif')))                               # get univariate / first raster
         
         if(!is.null(pattern2)) {                                                         # if bivariate,
            y <- rast(file.path(path, paste0(two[i], '.tif')))                            #    get 2nd raster
            result <- paste0(one[i], '__', two[i], '__', metrics[j])
         }
         else
            result <- paste0(one[i], '__', metrics[j])
         
         if(metrics[j] %in% c('mean', 'sd', 'NDVImean', 'NDVIsd'))                      # for focal metrics, include window size in result name
            result <- paste0(result, '_w', window)
         
         
         if(any(metrics %in% c('NDVI', 'NDVImean', 'NDVIsd')))                           # if we're doing any of the NDVI metrics,
            ndvi <- (x[[mica$nir]] - x[[mica$red]]) / (x[[mica$nir]] + x[[mica$red]])     #    calculate NDVI now
         
         
         switch(metrics[j],
                NDVI = {
                   z <- ndvi
                },
                NDRE = {
                   z <- (x[[mica$nir]] - x[[mica$re]]) / (x[[mica$nir]] + x[[mica$re]])
                },
                NDWIg = {
                   z <- (x[[mica$green]] - x[[mica$nir]]) / (x[[mica$green]] + x[[mica$nir]])
                },
                mean = {
                   z <- focal(x, w = window, fun = 'mean', na.policy = 'omit', na.rm = TRUE)
                },
                sd = {
                   z <- focal(x, w = window, fun = 'sd', na.policy = 'omit', na.rm = TRUE)
                },
                NDVImean = {
                   z <- focal(ndvi, w = window, fun = 'mean', na.policy = 'omit', na.rm = TRUE)
                },
                NDVIsd = {
                   z <- focal(ndvi, w = window, fun = 'sd', na.policy = 'omit', na.rm = TRUE)
                },
                NDWIswir = {
                   z <- (x[[mica$nir]] - y[[1]]) / (x[[mica$nir]] + y[[1]])
                },
                delta = {
                   z <- x - y
                }
         )
         
         
         type <- 'FLT4S'                       
         missing <- assessType(type)$noDataValue
         
         writeRaster(z, f <- file.path(path, paste0(result, '.tif')), overwrite = TRUE, 
                     datatype = type, NAflag = missing)
         message('Saved ', f)
         z <- x <- y <- ndvi <- NULL                                                      # free up memory
      }
   
   flights_prep(site, cache)
}
