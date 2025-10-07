#' Produce geoTIFF maps of predicted vegetation cover from fitted models
#' 
#' Console command to launch a prediction run via `do_map`, typically in a batch job on Unity.
#' 
#' @param fit Fit id in the fits database, fit object, or path to a .RDS with a
#'   fit object
#' @param site Three letter site code. If fitting from a fit id that was built
#'   on a single site, you may omit `site` to map the same site (this is the
#'   most common situation). If you want to map sites other than the site the
#'   model was built on, or the model was built on mutiple sites, `site` is
#'   required.
#' @param clip Optional clip, vector of `xmin`, `xmax`, `ymin`, `ymax`
#' @param result Optional result name. Default is 
#'    `map_<site>_<fit id>_[clip_<size>_ha]`; if a result name is specified, 
#'    the result will be `map_<result>_<site>_<fit id>_[clip_<size>_ha]`,
#'    retaining the site and fit id, as omiting these breaks your ability to
#'    track maps back to the fits they're based on.
#' @param resources Slurm launch resources. See \link[slurmcollie]{launch}.
#'   These take priority over the function's defaults.
#' @param local If TRUE, run locally; otherwise, spawn a batch run on Unity
#' @param trap If TRUE, trap errors in local mode; if FALSE, use normal R error
#'   handling. Use this for debugging. If you get unrecovered errors, the job
#'   won't be added to the jobs database. Has no effect if local = FALSE.
#' @param comment Optional launch / slurmcollie comment
#' @importFrom slurmcollie launch
#' @export


map <- function(fit, site = NULL, clip = NULL, result = NULL,
                resources = NULL, local = FALSE, trap = FALSE, comment = NULL) {
   
   
   if(is.list(fit)) {                                                                  # if fit is a list, it's (1) fit object,
      fitid <- NULL
      fitfile <- paste0('zz_', as.character(round(as.numeric(Sys.time())), '.RDS'))    #  make up a file name for the fit object to pass to do_fit
      saveRDS(fit, file.path(the$modelsdir, paste0('zz', fitid, 'fit_', '_extra.RDS')))#       and save it the model                        ************** what is this?
   }
   else {                                                                              # else, one of
      if(is.character(fit)) {                                                          #    if it's a character, it's (2) file name,
         fitid <- NULL                                                                 #       we'll read it in do_fit
         fitfile <- fit
      }
      else {                                                                           #    else, it's a number, so (3) fit id in database,
         fitid <- fit    
         
         load_database('fdb')
         fitrow <- the$fdb$id == fitid
         if(!any(fitrow))
            stop('Fit id ', fitid, ' not found in fits database')
      }
   }
   
   
   if(is.null(site)) {                                                                 # if no site specified, 
      if(!is.null(fitid))                                                              #    if fit is from database, use that, otherwise error
         site <- the$fdb$site[fitrow]
      else 
         stop('site must be supplied when fit is not from fits database')
   }
   else {
      site <- get_sites(site)                                                          # get one or more sites
   }
   if(length(site) != 1)
      stop('map requires exactly one site')
   
   
   com <- paste0(ifelse(is.null(fitid), '', paste0('map, fit id ', fitid)), 
                 ', site: ', site)
   if(!is.null(comment))                                                               # if comment supplied,
      comment <- paste0(comment, ' (', com, ')')                                       #    user comment, with default comment in parentheses
   else
      comment <- com                                                                   #    use default comment
   
   
   if(!is.null(fitid))                                                                 # if we're getting model from fit database,
      fitfile <- file.path(resolve_dir(the$modelsdir, site),
                           paste0('fit_', fitid, '_extra.RDS'))                        #       we'll pull fit from the database in do_fit
   
   
   resources <- get_resources(resources, list(                                         # define resources
      ncpus = 2,                                             
      memory = 400,                                                                    # SOR failed at 200 GB. WEL and PEG failed at 250 GB.
      walltime = '05:00:00'
   ))
   
   
   launch('do_map', 
          moreargs = list(site = site, fitid = fitid, fitfile = fitfile, 
                          clip = clip, result = result), 
          finish = 'map_finish', 
          #################callerid = the$mdb$id[i], 
          local = local, trap = trap, resources = resources, comment = comment)        # launch it
}