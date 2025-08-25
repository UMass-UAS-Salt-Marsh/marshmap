#' Produce geoTIFF maps of predicted vegetation cover from fitted models
#' 
#' Console command to launch a prediction run via `do_map`, typically in a batch job on Unity.
#' 
#' @param fit Model fit ID, fit object, or path to a .RDS with a fit object
#' @param site Three letter site code. If fitting from a fit id that was built on a single
#'    site, you may omit `site` to map the same site. If you want to map sites other than the 
#'    site the model was built on, or the model was built on mutiple sites, site is required.
#' @param clip Optional clip, vector of `xmin`, `xmax`, `ymin`, `ymax`
#' @param result Optional result filename or path and filename. If not provided, uses name from 
#'    database if it exists. Otherwise, constructs a name. If no path is supplied, `the$predicteddir`
#'    for the current site is used.
#' @param local If TRUE, run locally; otherwise, spawn a batch run on Unity
#' @param comment Optional map/slurmcollie comment
#' @importFrom slurmcollie launch
#' @export


map <- function(fit, site = NULL, clip = NULL, result = NULL, local = FALSE, comment = paste0('Map')) {
   
   
   if(is.list(fit)) {                                                                  # if fit is a list, it's (1) fit object,
      fitid <- NULL
      fitfile <- paste0('zz_', as.character(round(as.numeric(Sys.time())), '.RDS'))    #       make up a file name to pass to do_fit
      writeRDS(fit, file.path(the$modelsdir, paste0('zz', fitid, '_extra.RDS')))       #       and save it the model
   }
   else {                                                                              #    else, one of
      if(is.character(fit))                                                            #    if it's a character, it's (2) file name,
         fitid <- NULL                                                                 #       we'll read it in do_fit
      else {                                                                           #    else, it's a number, so (3) fit id in database,
         fitid <- fit                                               
         fitfile <- file.path(the$modelsdir, paste0(fitid, '_extra.RDS'))              #       we'll pull fit from database in do_fit
      }
   }
   
   
   if(is.null(site)) {                                                                 # if no site specified, 
      if(!is.null(fitid))                                                              #    if fit is from database, use that, otherwise error
         site <- the$fdb$site
      else 
         stop('site must be supplied when fit is not from fits database')
   }
   else {
      site <- get_sites(site)                                                          # get one or more sites
   }
   if(length(site != 1))
      stop('map requires exactly one site')
   
   
   
   
   
   res_path <- resolve_dir(the$predicteddir, site)                                     # default result path
   if(is.null(result)) {                                                               # if no result name supplied,
      ts <- stamp('2025-Mar-25_13-18', quiet = TRUE)                                   #    set format for timestamp in filename                         
      result <- file.path(res_path, paste0('map_', the$site, '_', ts(now())))          #    base result filename
   }
   else if(dirname(result) == '.')                                                     # else, if we have a result with no path,
      result <- file.path(res_path, result)                                            #    use default path
   
   
   resources <- get_resources(resources, list(
      # ncpus = 1,                                             
      # memory = 32,
      walltime = '00:10:00'
   ))
   
   
   launch('do_map', 
          moreargs = list(site = site, fitid = fitid, fitfile = fitfile, 
                          result = result, clip = clip), 
          finish = 'map_finish', callerid = the$mdb$id[i], 
          local = local, trap = trap, resources = resources, comment = comment)
}