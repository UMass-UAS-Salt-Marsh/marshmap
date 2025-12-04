#' Adds more metrics to an already existing upscaled clone
#' 
#' - this is experimental
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
#' @param comment Optional slurmcollie comment
#' @importFrom slurmcollie launch get_resources
#' @export


upscale_more <- function(site, newsite, cellsize = 1, vars = '{*}', minscore = 0, 
                         maxmissing = 20, metrics = 'all', cache = TRUE,
                         resources = NULL, local = FALSE, trap = TRUE, comment = NULL) {
   
   
   resources <- get_resources(resources, list(
      ncpus = 1,
      memory = 64,
      walltime = '4:00:00'
   ))
   
   
   if(is.null(comment))
      comment <- paste0('upscale_more ', site, ' from ', newsite, ' (', cellsize, ' m)')
   
   launch('do_gather', reps = site, repname = 'site', 
          moreargs = list(newsite = newsite, cellsize = cellsize, vars = vars, 
                          minscore = minscore, maxmissing = maxmissing,
                          metrics = metrics, cache = cache), 
          local = local, trap = trap, resources = resources, comment = comment)
}
