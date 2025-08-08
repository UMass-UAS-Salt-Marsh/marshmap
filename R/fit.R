#' Fit models
#' 
#' @param site Site name, or vector of site names if fitting multiple sites.
#' @param datafile Name of data file. Extension `.RDS` must be included. If fitting 
#'    multiple sites, either use a single datafile name shared among sites, or a vector
#'    matching site.
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
#' @export


fit <- function(site = NULL, datafile = 'data.RDS', method = 'rf', 
                vars = NULL, exclude = NULL, years = NULL, maxmissing = 0.05, 
                top_importance = 20, holdout = 0.2, auc = TRUE,
                resources = NULL, local = FALSE, trap = TRUE, comment = NULL) {
   
   
   sites <- get_sites(site)                                                                  # get one or more sites
   tryCatch({                                                                                # repeat datafile to match
      sites$datafile <- datafile
   },
   error = function(cond)
      stop('Length of datafile doesn\'t match site')
   )
   
   z <- rep(NA, nrow(sites))                                                                 # make sure datafiles exist before launching
   for(i in seq(nrow(sites))) {
      sites$datafile[i] <- file.path(resolve_dir(the$samplesdir, sites$site[i]), 
                                     sites$datafile[i])
      z[i] <- file.exists(sites$datafile[i])
   }
   if(any(!z))
      stop('Missing sample files: ', paste(substring(sites$datafile[!z], nchar(the$basedir) + 2), 
                                          collapse = ', '))
   
   resources <- get_resources(resources, list(
      ncpus = 10,                                                                            # ************ NEED TO TUNE ALL OF THESE
      memory = 200,
      walltime = '02:00:00'
   ))
   
   if(is.null(comment))
      comment <- paste0('fit ', paste(site, collapse = ', '))
   
   launch('do_fit', 
          moreargs = list(sites = sites, method = method,
                          vars = vars, exclude = exclude, years = years, 
                          maxmissing = maxmissing, top_importance = top_importance,
                          holdout = holdout, auc = auc),
          local = local, trap = trap, resources = resources, comment = comment)
}
