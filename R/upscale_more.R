#' Adds more metrics to an already existing upscaled clone
#' 
#' - this is experimental
#' 
#' @param site Site name
#' @param newsite Name for cloned site
#' @param cellsize Cell size for new site (m)
#' @param metrics A list of metrics, or 'all' for all metrics. May include any of:
#'  - `sd` Standard deviation
#'  - `q05`, `q10`, `q25`, `median`, `q75`, `q90`, and `q95` Quantiles
#'  - `r0595`, `r1090`, `iqr` Quantile ranges: 5th-95th, 10th-90th, and interquartile range
#'  - `skewness` and `kurtosis`, for Ryan
#' @param cache If TRUE, build cached images for `screen`
#' @importFrom terra rast datatype res aggregate writeRaster
#' @importFrom tools file_path_sans_ext
#' @importFrom stats quantile IQR
#' @importFrom moments skewness kurtosis
#' @export


upscale_more <- function(site, newsite, cellsize, metrics = 'all', cache = TRUE) {
   
   
   # metrics sd, median, skewness, and kurtosis are already defined. Here are the rest:
   q05 <- function(x) quantile(x, 0.05)
   q10 <- function(x) quantile(x, 0.10)
   q25 <- function(x) quantile(x, 0.25)
   q75 <- function(x) quantile(x, 0.75)
   q90 <- function(x) quantile(x, 0.90)
   q95 <- function(x) quantile(x, 0.95)
   
   r0595 <- function(x) diff(quantile(x, c(0.05, 0.95)), 1)
   r1090 <- function(x) diff(quantile(x, c(0.05, 0.95)), 1)
   iqr <- function(x) IQR(x)
   
   
   if(length(metrics) == 1 & metrics[1] == 'all')
      metrics <- c('sd', 'q05', 'q10', 'q25', 'median', 'q75', 'q90', 'q95', 'r0595', 'r1090', 'iqr', 'skewness', 'kurtosis')
   
   source <- resolve_dir(the$flightsdir, site)
   result <- resolve_dir(the$flightsdir, newsite)
   
   
   db_name <- paste0('flights_', site, '.txt')                                      # copy flights database and nuke stuff we don't want to keep
   db <- read.table(file.path(source, db_name), 
                    sep = '\t', quote = '', header = TRUE)
   db <- db[!db$deleted & nchar(db$window) == 0 & db$score != 1 ]                   # we're keeping everything but deleted, upscaled and rejected orthos
   orthos <- db$name                                                                # target orthos
   
   
   x <- rast(file.path(result, orthos[1]))                                          # get rescaling factor from (previously-processed) first raster
   x <- project(x, 'epsg:26986')
   factor <- round(cellsize / res(x)[1])                                            # integer rescaling factor
   message('Rescaling factor = ', factor)
   
   
   for(i in seq_along(orthos)) {                                                    # for each ortho,
      message('Processing ', orthos[i], ' (', i, ' of ', length(orthos), ')...')
      
      x <- rast(file.path(source, orthos[i]))                                       #    read raster
      type <- datatype(x, bylyr = FALSE)                                            #    get datatype and missing
      missing <- get_NAflag(x) 
      
      for(j in seq_along(metrics)) {                                                #    for each metric
         x <- terra::aggregate(x, factor, fun = fns[j])                             #       use aggregate to upscale
         name <- paste0(file_path_sans_ext(orthos[i]), '__', metrics[j], '.tif')    #       result file name
         writeRaster(x, file.path(result, name), 
                     overwrite = TRUE, datatype = type, NAflag = missing)           #       save raster
      }
   }
   
   
   message('New metrics added. Now running flights_prep')
   flights_prep(newsite, cache = cache)
   message('Finished upscaling orthos')
}
