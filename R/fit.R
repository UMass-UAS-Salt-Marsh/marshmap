#' Fit models
#' 
#' @param site Site name, or vector of site names if fitting multiple sites.
#' @param datafile Name of data file. Extension `.RDS` must be included. If fitting 
#'    multiple sites, either use a single datafile name shared among sites, or a vector
#'    matching site.
#' @param name Optional model name
#' @param method One of `rf` for Random Forest, `boost` for AdaBoost. Default = `rf`.
#' @param vars An optional vector of variables to restrict analysis to. Default = NULL, 
#'    all variables.
#' @param exclude An optional vector of variables to exclude.
#' @param years An optional vector of years to restrict variables to.
#' @param maxmissing Maximum proportion of missing training points allowed before a 
#'    variable is dropped.
#' @param top_importance Give number of variables to keep for variable importance.
#' @param holdout Proportion of points to hold out. For Random Forest, this specifies 
#'    the size of the single validation set, while for boosting, it is the size of each
#'    of the testing and validation sets.
#' @param auc If TRUE, calculate class probabilities so we can calculate AUC.
#' @param hyper Hyperparameters. ***To be defined.***
#' @param resources Slurm launch resources. See \link[slurmcollie]{launch}. These take priority
#' #'    over the function's defaults.
#' @param local If TRUE, run locally; otherwise, spawn a batch run on Unity
#' @param trap If TRUE, trap errors in local mode; if FALSE, use normal R error handling. Use this
#'   for debugging. If you get unrecovered errors, the job won't be added to the jobs database. Has
#'   no effect if local = FALSE.
#' @param comment Optional launch / slurmcollie comment
#' @importFrom lubridate now
#' @export


fit <- function(site = NULL, datafile = 'data.RDS', name = '', method = 'rf', 
                vars = NULL, exclude = NULL, years = NULL, maxmissing = 0.05, 
                top_importance = 20, holdout = 0.2, auc = TRUE, hyper = NULL,
                resources = NULL, local = FALSE, trap = TRUE, comment = NULL) {
   
   
   sites <- get_sites(site)                              # get one or more sites
   tryCatch({                                            # repeat datafile to match
      sites$datafile <- datafile
   },
   error = function(cond)
      stop('Length of datafile doesn\'t match site')
   )
   
   z <- rep(NA, nrow(sites))                             # make sure datafiles exist before launching
   for(i in seq(nrow(sites))) {
      sites$datafile[i] <- 
         file.path(resolve_dir(the$samplesdir, sites$site[i]), 
                   sites$datafile[i])
      z[i] <- file.exists(sites$datafile[i])
   }
   if(any(!z))
      stop('Missing sample files: ', 
           paste(substring(sites$datafile[!z], nchar(the$basedir) + 2), 
                 collapse = ', '))
   
   resources <- get_resources(resources, list(
      ncpus = 10,                                        # ************ NEED TO TUNE ALL OF THESE
      memory = 200,
      walltime = '02:00:00'
   ))
   
   if(is.null(comment))
      comment <- paste0('fit ', paste(site, collapse = ', '))
   
   
   
   new_db('fdb')                                         # Create new database
   the$fdb[i <- nrow(the$fdb) + 1, ] <- NA               # add rows to database 
   
   the$fdb$id[i] <- the$last_fit_id + 1                  # model id
   the$fdb$name[i] <- name                               # optional model name
   the$fdb$site[i] <- paste(sites, collapse = ', ')      # site (or sites) model is fit to
   the$fdb$method[i] <- method                           # modeling approach used (rf[i] <- random forest, ab[i] <- AdaBoost, perhaps others)
   the$fdb$model[i] <- NA                                # user-specified model, set in do_fit, resolved in fit_finish
   the$fdb$full_model[i] <- NA                           # complete model specification, set in do_fit, resolved in fit_finish
   the$fdb$hyper[i] <- NA                                # hyperparameters, set in do_fit, resolved in fit_finish
   the$fdb$success[i] <- NA                              # run success; NA = not run yet
   the$fdb$launched[i] <- now()                          # date and time launched (may disagree with slurmcollie by a couple of seconds)
   the$fdb$status[i] <- NA                               # final slurmcollie status, resolved in fit_finish
   the$fdb$error[i] <- NA                                # TRUE if error, resolved in fit_finish
   the$fdb$message[i] <- NA                              # error message if any, resolved in fit_finish
   the$fdb$cores[i] <- NA                                # cores requested, resolved in fit_finish
   the$fdb$cpu[i] <- NA                                  # CPU time, resolved in fit_finish
   the$fdb$cpu_pct[i] <- NA                              # percent CPU used, resolved in fit_finish
   the$fdb$mem_req[i] <- NA                              # memory requested (GB), resolved in fit_finish
   the$fdb$mem_gb[i] <- NA                               # memory used (GB), resolved in fit_finish
   the$fdb$walltime[i] <-  NA                            # elapsed run time, resolved in fit_finish
   the$fdb$CCR[i] <- NA                                  # correct classification rate, resolved in fit_finish
   the$fdb$kappa[i] <- NA                                # Kappa, resolved in fit_finish
   the$fdb$F1[i] <- NA                                   # F1 statistic, resolved in fit_finish
   the$fdb$predicted[i] <- NA                            #  name of predicted geoTIFF, added by map
   the$fdb$score[i] <- NA                                # subjective scoring field, *** added with function TBD ***
   the$fdb$comment_launch[i] <- comment                  # comment set at launch
   the$fdb$comment_assess[i] <- ''                       # comment based on assessment, *** added with function TBD ***
   the$fdb$comment_map[i] <- ''                          # comment based on final map, *** added with function TBD ***
   
   
   the$last_fit_id <- the$fdb$id[i]                      # save last_fit_id
   save_database('fdb')
   
   
   launch('do_fit', 
          moreargs = list(sites = sites, name = name, method = method,
                          vars = vars, exclude = exclude, years = years, 
                          maxmissing = maxmissing, top_importance = top_importance,
                          holdout = holdout, auc = auc, hyper = hyper),
          finish = 'fit_finish', callerid = the$fdb$id[i], 
          local = local, trap = trap, resources = resources, comment = comment)
}
