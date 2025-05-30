#' Build a geoTIFF map of predictions for specified model fit
#' 
#' Console command to launch a prediction run via `do_map`, typically in a batch job on Unity.
#' 
#' @param fit Model ID, fit filename, or fit object - figure it out)
#' @param site Three-letter site abbreviation
#' @param clip Optional clip, vector of `xmin`, `xmax`, `ymin`, `ymax`
#' @param result Optional result filename or path and filename. If not provided, uses name from 
#'    database if it exists. Otherwise, constructs a name. If no path is supplied, `the$predicteddir`
#'    for the current site is used.
#' @param batch If TRUE, spawn a batch run on Unity; otherwise run locally
#' @importFrom slurmcollie launch
#' @export


map <- function(fit, site = the$site, clip = NULL, result = NULL, batch = FALSE) {
   
   
   if(!is.list(fit)) {                                                                 # if fit isn't a list (thus a fit object),
      if(is.character(fit))                                                            #    if it's a character (thus a file name),
         fit <- readRDS(fit)                                                           #       read it
      else                                                                             #    else, it's a number (thus fit id in database),
         print('load fit from databse')                                                #       pull fit from database
   }                                                                                   # otherwise, it's already a fit object
   
   
   if(is.null(site) & is.null(the$site))                                               # get the site
      stop('Site name isn\'t already specified; it must be set with the site option')
   if(is.null(site))
      site <- the$site
   the$site <- site                                                                    # and save it
   
   
   res_path <- resolve_dir(the$predicteddir, site)                                     # default result path
   if(is.null(result)) {                                                               # if no result name supplied,
      ts <- stamp('2025-Mar-25_13-18', quiet = TRUE)                                   #    set format for timestamp in filename                         
      result <- file.path(res_path, paste0('map_', the$site, '_', ts(now())))          #    base result filename
   }
   else if(dirname(result) == '.')                                                     # else, if we have a result with no path,
      result <- file.path(res_path, result)                                            #    use default path
   
   
   source <- resolve_dir(the$flightsdir, site)
   runinfo <- paste0(result, '.RDS')
   
   if(batch) {                                                                         # if it's a batch run on Unity,
      print('spawning the run on Unity')
      
      launch('do_map') #################################### this is a stub
      # spawn batch run
      
      # we'll collect job stats later when the job is done with sweep
      # Run info file returns some stats; I get others from https://github.com/birdflow-science/BirdFlowPipeline/blob/main/R/get_job_efficiency.R  
   }
   else                                                                                # else, it's a local run right now
      do_map(fit, sourcedir = source, result = result, runinfo = runinfo, clip = clip)
}