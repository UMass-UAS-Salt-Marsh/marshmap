#' Produce geoTIFF maps of predicted vegetation cover from fitted models
#' 
#' Console command to launch a prediction run via `do_map`, typically in a batch job on Unity.
#' 
#' @param fit Fit id in the fits database, fit object, or path to a .RDS with a
#'   fit object
#' @param site Three letter site code. If fitting from a fit id that was built
#'   on a single site, you may omit `site` to map the same site (this is the
#'   most common situation). If you want to map sites other than the site the
#'   model was built on, or the model was built on multiple sites, `site` is
#'   required.
#' @param clip Optional clip, vector of `xmin`, `xmax`, `ymin`, `ymax`
#' @param result Optional result name. Default is 
#'    `map_<site>_<fit id>_[clip_<size>_ha]`; if a result name is specified, 
#'    the result will be `map_<result>_<site>_<fit id>_[clip_<size>_ha]`,
#'    retaining the site and fit id, as omitting these breaks your ability to
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
      site <- get_sites(site)$site                                                     # get one or more sites
   }
   if(length(site) != 1)
      stop('map requires exactly one site')
   
   
   if(!is.null(clip)) {                                                                # if there's a clip, modify result name
      browser()
      clip_area <- round(extent_area(clip))                        #     *********************** this needs modifying thanks to change to Mass State Plane *******************************
      cr <- paste0('clip_', clip_area, '_ha')
   }
   else
      cr <- ''
   
   result <- paste('map', result, site, fitid, cr, sep = '_')                          # make result name, sans extension
   result <- gsub('_$', '', gsub('__', '_', result))                                   # clean up from missing result, fitid, or cr
   
   
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
      memory = 500,                                                                    # PEG failed at 400 GB.
      walltime = '05:00:00'
   ))
   
   
   
   load_database('mdb')                                                                # Get map database
   the$mdb[i <- nrow(the$mdb) + 1, ] <- NA                                             # add row to database 
   
   the$mdb$mapid[i] <- max(the$mdb$mapid, 9000, na.rm = TRUE) + 1                      # mapids start at 9000
   the$mdb$fitid[i] <- fitid                                                           # id of fit map was based on (if known)
   the$mdb$site[i] <- site                                                             # site (or sites) model is fit to
   the$mdb$model[i] <- fitfile                                                         # full path to fit object, if not from the fits database
   the$mdb$result[i] <- file.path(resolve_dir(the$mapsdir, site), 
                                  paste0(result, '.tif'))                              # full path to resulting geoTIFF
   if(!is.null(clip)) {
      the$mdb$clip[i] <- list(clip)                                                    # clip vector or NA if not clipped 
      the$mdb$clip_area[i] <- list(clip_area)                                          # area of clip in ha or NA if not clipped
   }
   the$mdb$mpix[i] <- NA                                                               # megapixels of result file, resolved in map_finish
   the$mdb$success[i] <- NA                                                            # run success; NA = not run yet
   the$mdb$status[i] <- ''                                                             # final slurmcollie status, resolved in map_finish
   the$mdb$error[i] <- NA                                                              # TRUE if error, resolved in map_finish
   the$mdb$message[i] <- ''                                                            # error message if any, resolved in map_finish
   the$mdb$cores[i] <- NA                                                              # cores requested, resolved in map_finish
   the$mdb$cpu[i] <- ''                                                                # CPU time, resolved in map_finish
   the$mdb$cpu_pct[i] <- ''                                                            # percent CPU used, resolved in map_finish
   the$mdb$mem_req[i] <- NA                                                            # memory requested (GB), resolved in map_finish
   the$mdb$mem_gb[i] <- NA                                                             # memory used (GB), resolved in map_finish
   the$mdb$walltime[i] <-  ''                                                          # elapsed run time, resolved in map_finish
   
   the$mdb$launched[i] <- now()                                                        # date and time launched (may disagree with slurmcollie by second or two)
   save_database('mdb')
   
   
   
   launch('do_map', 
          moreargs = list(site = site, fitid = fitid, fitfile = fitfile, 
                          clip = clip, result = result, mapid = the$mdb$mapid[i]), 
          finish = 'map_finish', callerid = the$mdb$mapid[i], 
          local = local, trap = trap, resources = resources, comment = comment)        # launch it
}