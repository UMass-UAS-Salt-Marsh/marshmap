#' Fit models
#' 
#' @param fitid Fit id in the fits database
#' @param sites Data frame with `site` (3 letter code), `site_name` (long name), and 
#'    `datafile` (resolved path and filename of datafile). Sites, paths, and filenames
#'    are vetted by fit - there's no checking here.
#' @param name Optional model name
#' @param method One of `rf` for Random Forest, `boost` for AdaBoost. Default = `rf`.
#' @param vars An optional vector of variables to restrict analysis to. Default = NULL, 
#'    all variables. You may use portable names (in full or via regex), file names (in
#'    full or via regex), or search names. If you use file names, with multiple sites,
#'    these must match portable names in any site, which will be used for all sites.
#' @param exclude An optional vector of variables to exclude. Names are specified as for 
#'    `vars`.
#' @param years An optional vector of years to restrict variables to
#' @param maxmissing Maximum proportion of missing training points allowed before a 
#'    variable is dropped
#' @param top_importance Number of variables to keep for variable importance
#' @param holdout Proportion of points to hold out. For Random Forest, this specifies 
#'    the size of the single validation set, while for boosting, it is the size of each
#'    of the testing and validation sets.
#' @param auc If TRUE, calculate class probabilities so we can calculate AUC
#' @param hyper Hyperparameters ***To be defined***
#' @param rep Throwaway argument to make `slurmcollie` happy
#' @importFrom caret createDataPartition trainControl train varImp confusionMatrix
#' @importFrom stats complete.cases predict reformulate
#' @importFrom lubridate interval as.duration stamp now
#' @importFrom stringr str_extract
#' @importFrom dplyr bind_rows
#' @export


do_fit <- function(fitid, sites, name, method = 'rf', 
                   vars = NULL, exclude = NULL, years = NULL, maxmissing = 0.05, 
                   top_importance = 20, holdout = 0.2, auc = TRUE, hyper, rep = NULL) {
   
   
   timestamp <- function() {                                                              # Nice local timestamp in brackets (gives current time at call)
      ts <- stamp('[17 Feb 2025, 3:22:18 pm]  ', quiet = TRUE)
      ts(with_tz(now(), 'America/New_York'))
   }
   
   message('\n\n', timestamp(), 'Model fit id ', fitid, ifelse(nchar(name) > 0, paste0(' (', name, ')'), ''))
   
   if(nrow(sites) > 1)
      message('Merging datafiles for ', nrow(sites), ' sites...')
   
   r <- list()
   for(i in seq_len(nrow(sites)))                                                         # read data files and merge them
      r[[i]] <- readRDS(sites$datafile[i])
   names(r) <- sites$site
   r <- bind_rows(r, .id = 'site')
   r$subclass <- as.factor(r$subclass)                                                    # we want subclass to be factor, not numeric
   
   
   # want to assess how much of a mess we've made by combining sites. I guess we'll drop stuff with too many missing as usual
   # do want to produce a report with % missing for each var, number of vars with >10, 25, 50% missing, stuff like that
   
   
   message('\nFitting for site', ifelse(nrow(sites) != 1, 's', ''), ' = ', paste(sites$site, collapse = ', '))
   
   
   v <- unique(gsub('-', '_', find_orthos(sites$site, vars)$portable))                    # portable names from vars (replace dash with underscore to match var names)
   if(!is.null(v)) {                                                                      # if restricting to selected variables,
      r <- r[, sub('_\\d$', '', names(r)) %in% c('site', 'subclass', v)]
      if(vars != '{*}')
         message('Analysis limited to ', sum(!names(r) %in% c('site', 'subclass')), 
                 ' selected variables')
   }
   
   e <- unique(gsub('-', '_', find_orthos(sites$site, exclude)$portable))                 # portable names from exclude
   if(!is.null(exclude)) {                                                                # if excluding variables,
      r <- r[, !sub('_\\d$', '', names(r)) %in% e] 
      if(exclude != '')
         message('Analysis limited to ', sum(!names(r) %in% c('site', 'subclass')), 
                 ' variables after exclusions')
   }
   
   if(sum(!names(r) %in% c('site', 'subclass')) <= 1)
      stop('Analysis doesn\'t include any orthoimage variables')
   
   r <- r[, !names(r) == 'site']                                                          # finally drop site name (not sure if we'll want it at some point, so I've kept it up to here)
   
   
   if(!is.null(years)) {                                                                  # if restricting to selected years,
      d <- stringr::str_extract(names(r), '(_)(\\d{4})_', group = 2) |>                   #    extract year from variable names
         as.numeric()
      d <- d %in% years 
      r <- r[, c(TRUE, d[-1])]
      message('Analysis limited to ', length(names(r)) - 1, ' variables by year (', 
              paste(years, collapse = ', '), ')')
   }
   
   
   r <- r[, c(TRUE, colSums(is.na(r[, -1])) / dim(r)[1] <= maxmissing)]                   # drop variables with too many missing values
   
   
   if(auc)                                                                                # if preparing data for AUC, 
      r$subclass <- as.factor(paste0('class', r$subclass))                                #    we can't use numbers for factors when doing classProbs in training
   
   
   n_partitions <- switch(method, 
                          'rf' = 1,                                                       # random forest uses a single validation set,
                          'boost' = 2)                                                    # and AdaBoost uses a test and a validation set
   parts <- createDataPartition(r$subclass, p = holdout, times = n_partitions)            # create holdout sets
   
   training <- r[-unlist(parts), ]
   validate <- r[parts[[1]], ]
   if(method == 'boost')
      test <- r[parts[[2]], ]
   
   
   
   switch(method, 
          'rf' = {
             meth <- 'ranger'
             if(auc)                                                                      #    if prepping for AUC,
                control <- trainControl(method = "cv",                                    #       add necessary items to training control        ***** check these--are they all needed here??????
                                        number = 5,
                                        classProbs = TRUE,
                                        savePredictions = "final"
                )
             else                                                                         #    else,
                control <- trainControl(allowParallel = TRUE)                             #       controls for random forests, no AUC
          },
          'boost' = {
             meth <- 'adaboost'
             control <- trainControl()                                                    # conrols for AdaBoost
          }
   )  
   
   # tuning ...
   
   training <- training[complete.cases(training), ]                                       # only use complete cases   ....................... 
   # na.action = 'na.omit' fails, but na.learn fails. Maybe impute values? Some vars are missing for half of site. Some subclasses have no complete rows.
   # all I can make work so far is using complete cases
   # training <- training[!training$subclass %in% c(7, 10, 11, 26, 33), ]     # try this. Nope.
   
   
   t <- length(levels(training$subclass))
   training$subclass <- droplevels(training$subclass)
   if(dropped <- length(levels(training$subclass)) - t > 0)
      message(dropped, ' levels dropped because of missing values')
   
   model <- reformulate(names(training)[-1], 'subclass')
   
   message('Training set has ', dim(training)[2] - 1, ' predictor variables and ', dim(training)[1], ' cases')
   
   
   a <- Sys.time()
   z <- train(model, data = training, method = meth, trControl = control, num.threads = 0, importance = 'impurity')             #---train the model
   #    z <- train(model, data = training, method = meth, trControl = control, num.threads = 0, importance = 'impurity', tuneGrid = expand.grid(.mtry = 1, .splitrule = 'gini', .min.node.size = c(10, 20)))
   
   
   validate <- validate[complete.cases(validate), ]
   validate$subclass <- droplevels(validate$subclass)
   y <- stats::predict(z, newdata = validate)                                             # --- validate the model on the holdout set
   
   
   
   message('Elapsed time for training = ',  as.duration(round(interval(a, Sys.time()))))
   
   
   confuse <- unconfuse(confusionMatrix(validate$subclass, y, mode = 'prec_recall'))
   
   f <- assess(model = list(fit = z, confuse = confuse, nvalidate = dim(validate)[1], 
                            id = fitid, name = name),
               top_importance = top_importance)                                           # --- model assessment
   
   
   r <- list()                                                                            # --- write info from run and assessment to temporary RDS for fit_finish
   r$model <- gsub('\\s+', ' ', deparse1(model, collapse = ''))                           # user-specified model in well-behaved text format
   
   r$full_model <- 'tbd' # full_model                                                          # complete model specification          ************************** need these
   r$hyper <- 'tbd' # hyper                                                                    # hyperparameters
   
   r$vars <- ncol(z$train)                                                                # number of variables
   r$cases <- nrow(z$train)                                                               # sample size   
   r$holdout <- dim(validate)[1]                                                          # holdout sample size
   r$CCR <- f$confusion$overall[['Accuracy']]                                             # correct classification rate
   r$kappa <- f$confusion$overall[['Kappa']]                                              # Kappa
   
   saveRDS(r, file.path(the$modelsdir, paste0('zz_', fitid, '_fit.RDS')))
   
   
   # --- write info that doesn't fit in a table (and more importantly, is BIG) to <id>_extra.RDS
   
   r <- list()
   
   r$model_object <- z                                                                    # model object
   r$confuse <- f$confusion                                                               # confusion matrix                        
   r$varimp <- f$importance                                                               # variable importance
   
   saveRDS(r, file.path(the$modelsdir, paste0(fitid, '_extra.RDS')))
   
   message('Model fit finished; results written to temporary and extra files')
}
