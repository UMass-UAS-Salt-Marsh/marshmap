#' Create derived variables such as NDVI and NDRE
#' 
#' This function creates any of a number of univariate and bivariate metrics derived from
#' raster data, such as NDVI and NDRE. Results are written as rasters to the `flights` directory,
#' with the metric included in the name. These metrics will be treated like source layers in 
#' subsequent processing and modeling.
#' 
#' For univariate metrics, supply one or more layer names via `pattern1`. All metrics will be 
#' calculated for each layer specified by `pattern1`. Results will be named `<layer>__<metric>`.
#' 
#' For bivariate metrics, speicfy matched pairs of layers with `pattern1` and `pattern2`. It's
#' best to specify complete names (you can use vectors for each) so the layers are paired properly.
#' If you're crazy enough to use patterns here, scrutinize the result names carefully.
#' Results will be named `<layer1>_<layer2>__metric`. At the moment, `delta` is the only bivariate
#' metric. 
#' 
#' This fits in the workflow after `gather` and before `sample`.
#' 
#' @param site One or more site names, using 3 letter abbreviation. If running in batch mode, each 
#'    named site will be run in a separate job.
#' @param pattern1 Regex filtering rasters, case-insensitive. Default = "" (match all). Note: only 
#'    files ending in `.tif` are included in any case. `pattern1` may alternatively be a vector 
#'    of layer names (or patterns if you want to get tricky). See details.
#' @param pattern2 A second pattern or vector of layer names, used for bivariate metrics. See details.
#' @param metrics A list of metrics to apply. Univariate metrics include:
#' \describe{
#'    \item{NDVI}{Normalized difference vegetation index, (NIR - red) / (NIR + red), an index of biomass}
#'    \item{NDWIg}{Normalized difference water index (green), (green - NIR) / (green + NIR),
#'       primarily helps distingish waterbodies}
#'    \item{NDRE}{Normalized difference red edge index, (NIR - RE) / (NIR + RE), an index of the
#'       amount of chlorophil in a plant}
#'    \item{NDVI_mean}{mean of NDVI in a window, size defined by `window`}
#'    \item{NDVI_std}{standard deviation of NDVI in a window, size defined by `window`}
#'    Bivariate metrics include:
#'    \item{NDWIswir}{Normalized difference water index (SWIR), (NIR - SWIR) / (NIR + SWIR),
#'       an index of water content in leaves; requires a Mica layer for `pattern1`, and a matched
#'       SWIR layer for `pattern2`}
#'    \item{delta}{The difference between `pattern1` and `pattern2`, may be useful for taking a 
#'    difference between late-season and early-season DEMs to represent vegetation canopy height}
#' }
#' @param window Window size for NDVI_mean and NDVI_std, in cells; windows are square, so just specify
#'    a single number. Bonus points if you remember to make it odd.
#' @param local If TRUE, run locally; otherwise, spawn a batch run on Unity
#' @param trap If TRUE, trap errors in local mode; if FALSE, use normal R error handling. Use this
#'   for debugging. If you get unrecovered errors, the job won't be added to the jobs database. Has
#'   no effect if local = FALSE.
#' @param comment Optional slurmcollie comment
#' @importFrom slurmcollie launch
#' @export

# Note: I have a list of 14 indices in an email from Steve Fickas, 5 May 2025


derive <- function(site, pattern1 = '', pattern2 = NULL, metrics = c('NDVI', 'NDWI', 'NDRE'),
                   window = 3, local = FALSE, trap = TRUE, comment = NULL) {
   
   
   resources <- list(ncpus = 1,
                     memory = 100,
                     walltime = '20:00:00'
   )
   
   if(is.null(comment))
      comment <- paste0('derive ', paste(site, collapse = ', '), '(', paste(metrics, collapse = ', '), ')')
   
   launch('do_derive', reps = site, repname = 'site', 
          moreargs = list(pattern = pattern1, pattern2 = pattern2, metrics = metrics),
          local = local, trap = trap, resources = resources, comment = comment)
   
}
