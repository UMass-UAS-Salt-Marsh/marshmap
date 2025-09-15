#' Build statistical models of vegetation cover
#' 
#' Given one or more sites and a model specification, builds a model of vegetation
#' cover and report model assessment.
#' 
#' @param site Three letter site code, or vector of site names if fitting multiple sites
#' @param datafile Name of data file. It must be an `.RDS` file, but exclude the
#'   extension. If fitting multiple sites, either use a single datafile name
#'   shared among sites, or a vector matching site.
#' @param name Optional model name
#' @param method One of `rf` for Random Forest, `boost` for AdaBoost. Default = `rf`.
#' @param vars An optional vector of variables to restrict analysis to. Default = `{*}`, 
#'    all variables. `vars` is processed by `find_orthos`, and may include file names, 
#'    portable names, search names and regular expressions of file and portable names.
#' @param exclude An optional vector of variables to exclude. As with `vars`, variables
#'    are processed by `find_orthos`
#' @param years An optional vector of years to restrict variables to
#' @param minscore Minimum score for orthos. Files with a minimum score of less than
#'    this are excluded from results. Default is 0, but rejected orthos are always 
#'    excluded.
#' @param maxmissing Maximum percent missing in orthos. Files with percent missing greater
#'    than this are excluded.
#' @param max_miss_train Maximum proportion of missing training points allowed before a 
#'    variable is dropped
#' @param top_importance Number of variables to keep for variable importance
#' @param holdout Proportion of points to hold out. For Random Forest, this specifies 
#'    the size of the single validation set, while for boosting, it is the size of each
#'    of the testing and validation sets.
#' @param auc If TRUE, calculate class probabilities so we can calculate AUC
#' @param hyper Hyperparameters. ***To be defined.***
#' @param resources Slurm launch resources. See \link[slurmcollie]{launch}.
#'   These take priority over the function's defaults.
#' @param local If TRUE, run locally; otherwise, spawn a batch run on Unity
#' @param trap If TRUE, trap errors in local mode; if FALSE, use normal R error
#'   handling. Use this for debugging. If you get unrecovered errors, the job
#'   won't be added to the jobs database. Has no effect if local = FALSE.
#' @param comment Optional launch / slurmcollie comment
#' @importFrom lubridate now
#' @export


fit <- function(site = NULL, datafile = 'data', name = '', method = 'rf', 
                vars = '{*}', exclude = '', years = NULL, minscore = 0, 
                maxmissing = 20, max_miss_train = 0.20, top_importance = 20, 
                holdout = 0.2, auc = FALSE, hyper = NULL,
                resources = NULL, local = FALSE, trap = TRUE, comment = NULL) {
   
   
   sites <- get_sites(site)                              # get one or more sites
   
   datafile <- paste0(datafile, '.RDS')
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
      ncpus = 10,                                        # ************ NEED TO TUNE THESE
      memory = 200,
      walltime = '05:00:00'
   ))
   
   
   
   load_database('fdb')                                  # Create new database
   the$fdb[i <- nrow(the$fdb) + 1, ] <- NA               # add rows to database 
   
   the$fdb$id[i] <- the$last_fit_id + 1                  # model id
   the$fdb$name[i] <- name                               # optional model name
   the$fdb$site[i] <- paste(sites$site, collapse = ', ') # site (or sites) model is fit to
   
   if(is.null(comment))                                  # now that we know some stuff, make up default comment
      comment <- paste0('fit ', the$fdb$id[i], 
                        ifelse(nchar(name) > 0, paste0(' (', name, ')'), ''), 
                        ', site: ', paste(site, collapse = ', '))
   
   the$fdb$method[i] <- method                           # modeling approach used (rf[i] <- random forest, ab[i] <- AdaBoost, perhaps others)
   the$fdb$success[i] <- NA                              # run success; NA = not run yet
   the$fdb$status[i] <- ''                               # final slurmcollie status, resolved in fit_finish
   the$fdb$error[i] <- NA                                # TRUE if error, resolved in fit_finish
   the$fdb$message[i] <- ''                              # error message if any, resolved in fit_finish
   the$fdb$cores[i] <- NA                                # cores requested, resolved in fit_finish
   the$fdb$cpu[i] <- ''                                  # CPU time, resolved in fit_finish
   the$fdb$cpu_pct[i] <- ''                              # percent CPU used, resolved in fit_finish
   the$fdb$mem_req[i] <- NA                              # memory requested (GB), resolved in fit_finish
   the$fdb$mem_gb[i] <- NA                               # memory used (GB), resolved in fit_finish
   the$fdb$walltime[i] <-  ''                            # elapsed run time, resolved in fit_finish
   the$fdb$CCR[i] <- NA                                  # correct classification rate, resolved in fit_finish
   the$fdb$kappa[i] <- NA                                # Kappa, resolved in fit_finish
   the$fdb$predicted[i] <- ''                            # name of predicted geoTIFF, added by map
   the$fdb$score[i] <- NA                                # subjective scoring field, *** added with function TBD ***
   the$fdb$comment_launch[i] <- comment                  # comment set at launch
   the$fdb$comment_assess[i] <- ''                       # comment based on assessment, *** added with function TBD ***
   the$fdb$comment_map[i] <- ''                          # comment based on final map, *** added with function TBD ***
   the$fdb$call[i] <- 
      gsub('\\"', '\'', deparse(sys.calls()[[sys.nframe()]]))   # grab function call
   the$fdb$model[i] <- ''                                # user-specified model, set in do_fit, resolved in fit_finish
   the$fdb$full_model[i] <- ''                           # complete model specification, set in do_fit, resolved in fit_finish
   the$fdb$datafile[i] <- datafile                       # name of data file used
   
   the$fdb$hyper[i] <- ''                                # hyperparameters, set in do_fit, resolved in fit_finish
   
   message('Fit id is ', the$fdb$id[i])
   the$last_fit_id <- the$fdb$id[i]                      # save last_fit_id
   
   the$fdb$launched[i] <- now()                          # date and time launched (may disagree with slurmcollie by second or two)
   save_database('fdb')
   
   
   launch('do_fit', 
          moreargs = list(fitid = the$fdb$id[i], sites = sites, name = name, method = method,
                          vars = vars, exclude = exclude, years = years, minscore, maxmissing,
                          max_miss_train = max_miss_train, top_importance = top_importance,
                          holdout = holdout, auc = auc, hyper = hyper),
          finish = 'fit_finish', callerid = the$fdb$id[i], 
          local = local, trap = trap, resources = resources, comment = comment)
}
