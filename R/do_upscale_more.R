#' Adds more metrics to an already existing upscaled clone
#' 
#' - this is experimental
#' 
#' **Note**: all metrics *must* be added to pars.yml under category: derive.
#' 
#' @param site Site name
#' @param newsite Name for cloned site
#' @param cellsize Cell size for new site (m)
#' @param vars File names, portable names, regex matching either, or search names
#'    selecting files to upscale. See Image naming in
#'    [README](https://github.com/UMass-UAS-Salt-Marsh/marshmap/blob/main/README.md) 
#'    for details. The default is `{*}`, which will include all variables.
#' @param minscore Minimum score for orthos. Files with a minimum score of less than
#'    this are excluded. Default is 0, but rejected orthos are always 
#'    excluded.
#' @param maxmissing Maximum percent missing in orthos. Files with percent missing greater
#'    than this are excluded.
#' @param metrics A list of metrics, or 'all' for all metrics. May include any of:
#'  - `sd` Standard deviation
#'  - `q05`, `q10`, `q25`, `median`, `q75`, `q90`, and `q95` Quantiles
#'  - `r0595`, `r1090`, `iqr` Quantile ranges: 5th-95th, 10th-90th, and interquartile range
#'  - `skewness` and `kurtosis`, for Ryan
#' @param cache If TRUE, build cached images for `screen`
#' @param resources Slurm launch resources. See \link[slurmcollie]{launch}. These take priority
#' #'    over the function's defaults.
#' @param local If TRUE, run locally; otherwise, spawn a batch run on Unity
#' @param trap If TRUE, trap errors in local mode; if FALSE, use normal R error handling. Use this
#'   for debugging. If you get unrecovered errors, the job won't be added to the jobs database. Has
#'   no effect if local = FALSE.
#' @importFrom terra rast datatype res aggregate writeRaster
#' @importFrom tools file_path_sans_ext
#' @importFrom stats quantile IQR
#' @importFrom moments skewness kurtosis
#' @export


do_upscale_more <- function(site, newsite, cellsize, vars, minscore, maxmissing, metrics = 'all', cache = TRUE) {
   
   
   # metrics sd, median, skewness, and kurtosis are already defined. Here are the rest:
   sd <- function(x) stats::sd(x, na.rm = TRUE)
   
   q05 <- function(x) quantile(x, 0.05, na.rm = TRUE)
   q10 <- function(x) quantile(x, 0.10, na.rm = TRUE)
   q25 <- function(x) quantile(x, 0.25, na.rm = TRUE)
   q75 <- function(x) quantile(x, 0.75, na.rm = TRUE)
   q90 <- function(x) quantile(x, 0.90, na.rm = TRUE)
   q95 <- function(x) quantile(x, 0.95, na.rm = TRUE)
   
   r0595 <- function(x) diff(quantile(x, c(0.05, 0.95), na.rm = TRUE), 1)
   r1090 <- function(x) diff(quantile(x, c(0.05, 0.95), na.rm = TRUE), 1)
   iqr <- function(x) IQR(x, na.rm = TRUE)
   
   skewness <- function(x) moments::skewness(x, na.rm = TRUE)
   kurtosis <- function(x) moments::kurtosis(x, na.rm = TRUE)
   
   
   if(length(metrics) == 1 & metrics[1] == 'all')
      metrics <- c('sd', 'q05', 'q10', 'q25', 'median', 'q75', 'q90', 'q95', 'r0595', 'r1090', 'iqr', 'skewness', 'kurtosis')
   
   source <- resolve_dir(the$flightsdir, site)
   result <- resolve_dir(the$flightsdir, newsite)
   
   
   db_name <- paste0('flights_', site, '.txt')                                      # copy flights database and nuke stuff we don't want to keep
   db <- read.table(file.path(source, db_name), ,
                    sep = '\t', quote = '', header = TRUE)
   
   db$window[is.na(db$window)] <- ''
   db$score[is.na(db$score)] <- 0
   
   orthos <- find_orthos(site, vars, minscore, maxmissing)                          # find matching files
   orthos <- orthos[nchar(db$window[orthos$row]) == 0, ]$file                       # but don't want upscaled files

   
   x <- rast(file.path(source, orthos[1]))                                          # get rescaling factor from the first raster
   x <- project(x, 'epsg:26986')
   factor <- round(cellsize / res(x)[1])                                            # integer rescaling factor
   message('Rescaling factor = ', factor)
   
   
   for(i in seq_along(orthos)) {                                                    # for each ortho,
      message('Processing ', orthos[i], ' (', i, ' of ', length(orthos), ')...')
      
      x <- rast(file.path(source, orthos[i]))                                       #    read raster
      type <- datatype(x, bylyr = FALSE)                                            #    get datatype and missing
      missing <- get_NAflag(x) 
      
      
      for(j in seq_along(metrics)) {                                                #    for each metric
         cat('   metric: ', metrics[j], ' (', j, ' of ', length(metrics), ')\n', sep = '')
         z <- terra::aggregate(x, factor, fun = eval(parse(text = metrics[j])))     #       use aggregate to upscale
         name <- paste0(file_path_sans_ext(orthos[i]), '__', metrics[j], '.tif')    #       result file name
         writeRaster(z, file.path(result, name), 
                     overwrite = TRUE, datatype = type, NAflag = missing)           #       save raster
      }
   }
   
   
   message('New metrics added. Now running flights_prep')
   flights_prep(newsite, cache = cache)
   message('Finished upscaling orthos')
}
