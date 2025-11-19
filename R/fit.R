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
#' @param fitargs A named list of additional arguments to pass to the model (`ranger` or `boost`)
#' @param vars Vector of variables to restrict analysis to. Default = `{*}`, 
#'    all variables. `vars` is processed by `find_orthos`, and may include file names, 
#'    portable names, search names and regular expressions of file and portable names.
#' @param exclude_vars An optional vector of variables to exclude. As with `vars`, variables
#'    are processed by `find_orthos`
#' @param exclude_classes Numeric vector of subclasses to exclude. This overrides `fit_exclude`
#'    that may be included in `sites.txt`.
#' @param include_classes Numeric vector of subclasses to include - all other classes are dropped. 
#'    `include_classes` overrides `fit_exclude` (in `sites.txt`) and `exclude_classes`.
#' @param exclude_years A vector of one or more years of ground truth data to exclude (requires a
#'    year column in source data)
#' @param min_class Minimum number of training samples to allow in a class. All classes with
#'    fewer samples in training set as well as all classes with zero cases in the
#'    validation set will be dropped from the model. Use `min_class = NULL` to prevent 
#'    dropping any classes.
#' @param reclass Matrix or vector of paired classes to reclassify. Pass either a two column
#'    matrix, such that values in the first column are reclassifed to the second column, or a 
#'    vector with pairs, `reclass = c(13, 2, 3, 4)`, which would reclassify all 13s to 2 and 3s to 4, 
#'    lumping each pair of classes. Reclassifying is not iterative, thus you could swap 
#'    1s and 2s with `reclass = c(1, 2, 2, 1)`, not that you'd want to.
#' @param max_samples Maximum number of samples to use - subsample if necessary
#' @param years Vector of years to restrict variables to
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
#' @param bypoly The name of a `bypoly` cross-validation sequence in the sampled data. 
#'    `gather` creates `bypoly01` through `bypoly05`, with sequences of 1:10 for each 
#'    subclass. Poly groups 1 and 6 will be used as holdouts. To specify different groups, 
#'    use `blocks = list(block = 'bypoly01', classes = c(2, 7)`, for instance.
#' @param blocks An alternative to holding out random points. Specify a named list 
#'    with `block = <name of block column>, classes = <vector of block classes to hold out>`.
#'    Set this up by creating a shapefile corresponding to ground truth data with a variable
#'    `block` that contains integer block classes, and placing it in the `blocks/` directory
#'    for the site. `gather` and `sample` will collect and process block data for you to 
#'    use here.    
#' @param auc If TRUE, calculate class probabilities so we can calculate AUC
#' @param hyper Hyperparameters. ***To be defined.***
#' @param notune If TRUE, don't do hyperparameter tuning. This can cost you a few percent 
#'    in CCR, but will speed the run up six-fold from the default.
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
                fitargs = NULL,
                vars = '{*}', exclude_vars = '', exclude_classes = NULL, include_classes = NULL, 
                exclude_years = NULL, min_class = 500, reclass = c(13, 2), max_samples = NULL, years = NULL, 
                minscore = 0, maxmissing = 20, max_miss_train = 0.20, 
                top_importance = 20, holdout = NULL, bypoly = 'bypoly01', blocks = NULL,
                auc = FALSE, hyper = NULL, notune = FALSE,
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
      ncpus = 10,                                        
      memory = 16,
      walltime = '05:00:00'                              # I timed out a couple at 5 hours, but that was with 250k cases--way too many
   ))
   
   
   
   load_database('fdb')                                  # Get fit database
   the$fdb[i <- nrow(the$fdb) + 1, ] <- NA               # add row to database 
   
   the$fdb$id[i] <- the$last_fit_id + 1                  # model id
   the$fdb$name[i] <- name                               # optional model name
   the$fdb$site[i] <- paste(sites$site, collapse = ', ') # site (or sites) model is fit to
   
   
   com <- paste0('fit ', the$fdb$id[i], 
                 ifelse(nchar(name) > 0, paste0(' (', name, ')'), ''), 
                 ', site: ', paste(site, collapse = ', '))
   if(!is.null(comment))                                 # if comment supplied,
      comment <- paste0(comment, ' (', com, ')')         #    user comment, with default comment in parentheses
   else
      comment <- com                                     #    use default comment
   
   
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
   the$fdb$score[i] <- NA                                # subjective scoring field, may be added with fitinfo
   the$fdb$comment_launch[i] <- comment                  # comment set at launch
   the$fdb$comment_assess[i] <- ''                       # comment based on assessment, may be added with fitinfo
   the$fdb$comment_map[i] <- ''                          # comment based on final map, may be added with fitinfo
   the$fdb$call[i] <- 
      gsub('\\"', '\'', gsub('[ ]+', ' ', paste(deparse(sys.calls()[[sys.nframe()]]), collapse = ' ')))    # grab function call
   the$fdb$model[i] <- ''                                # user-specified model, set in do_fit, resolved in fit_finish
   the$fdb$full_model[i] <- ''                           # complete model specification, set in do_fit, resolved in fit_finish
   the$fdb$datafile[i] <- datafile                       # name of data file used
   
   the$fdb$hyper[i] <- ''                                # hyperparameters, set in do_fit, resolved in fit_finish
   
   message('Fit id is ', the$fdb$id[i])
   the$last_fit_id <- the$fdb$id[i]                      # save last_fit_id
   
   the$fdb$launched[i] <- now()                          # date and time launched (may disagree with slurmcollie by second or two)
   save_database('fdb')
   
   
   launch('do_fit', 
          moreargs = list(fitid = the$fdb$id[i], sites = sites, name = name, method = method, fitargs = fitargs,
                          vars = vars, exclude_vars = exclude_vars, exclude_classes = exclude_classes, 
                          include_classes = include_classes, exclude_years = exclude_years,
                          min_class = min_class, reclass = reclass, max_samples = max_samples, 
                          years = years, minscore = minscore, maxmissing = maxmissing, 
                          max_miss_train = max_miss_train, top_importance = top_importance, 
                          holdout = holdout, bypoly = bypoly, blocks = blocks, auc = auc, hyper = hyper, notune = notune),
          finish = 'fit_finish', callerid = the$fdb$id[i], 
          local = local, trap = trap, resources = resources, comment = comment)
}
