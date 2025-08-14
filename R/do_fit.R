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
#' @param years An optional vector of years to restrict variables to.
#' @param maxmissing Maximum proportion of missing training points allowed before a 
#'    variable is dropped.
#' @param top_importance Give number of variables to keep for variable importance.
#' @param holdout Proportion of points to hold out. For Random Forest, this specifies 
#'    the size of the single validation set, while for boosting, it is the size of each
#'    of the testing and validation sets.
#' @param auc If TRUE, calculate class probabilities so we can calculate AUC.
#' @param hyper Hyperparameters. ***To be defined.***
#' @param rep Throwaway argument for `slurmcollie`.
#' @importFrom caret createDataPartition trainControl train varImp confusionMatrix
#' @importFrom stats complete.cases predict reformulate
#' @importFrom lubridate interval as.duration
#' @importFrom stringr str_extract
#' @importFrom dplyr bind_rows
#' @export


do_fit <- function(fitid, sites, name, method = 'rf', 
                   vars = NULL, exclude = NULL, years = NULL, maxmissing = 0.05, 
                   top_importance = 20, holdout = 0.2, auc = TRUE, hyper, rep = NULL) {
   
   
   if(length(sites) > 1)
      message('Merging datafiles for ', nrow(sites), '...')
   
   x <- list()
   for(i in seq_len(sites))                                                               # read data files and merge them
      x[[i]] <- readRDS(sites$datafile[i])
   
   names(x) <- sites$site
   x <- bind_rows(x, .id = 'site')
   
   data$subclass <- as.factor(x$subclass)                                                 # we want subclass to be factor, not numeric
   
   
   ### *** do something with model name?
   ### *** when I write zz<id>.RDS, use fitid
   print(fitid)
   print(name)
   
   
   # want to assess how much of a mess we've made by combining sites. I guess we'll drop stuff with too many missing as usual
   # do want to produce a report with % missing for each var, number of vars with >10, 25, 50% missing, stuff like that
   
   
   message('\nFitting for site', (ifelse(nrow(sites) != 1, 's', '')), ' = ', paste(sites$site, collapse = ', '))
   
   
   v <- unique(find_orthos(sites$site, vars)$portable)                                    # portable names from vars
   if(!is.null(vars)) {                                                                   # if restricting to selected variables,
      x <- x[, names(x) %in% c('subclass', vars)]
      message('Analysis limited to ', length(names(x)) - 1, 
              ' selected variables')
   }
   
   
   e <- unique(find_orthos(sites$site, exclude)$portable)                                 # portable names from exclude
   if(!is.null(exclude)) {                                                                # if excluding variables,
      x <- x[, !names(x) %in% exclude]                                              
      message('Analysis limited to ', length(names(x)) - 1, 
              ' variables after exclusions')
   }
   
   
   if(!is.null(years)) {                                                                  # if restricting to selected years,
      d <- stringr::str_extract(names(x), '(_)(\\d{4})_', group = 2) |>                   #    extract year from variable names
         as.numeric()
      d <- d %in% years 
      x <- x[, c(TRUE, d[-1])]
      message('Analysis limited to ', length(names(x)) - 1, ' variables by year (', 
              paste(years, collapse = ', '), ')')
   }
   
   
   x <- x[, c(TRUE, colSums(is.na(x[, -1])) / dim(x)[1] <= maxmissing)]                   # drop variables with too many missing values
   
   
   if(auc)                                                                                # if preparing data for AUC, 
      x$subclass <- as.factor(paste0('class', x$subclass))                                #    we can't use numbers for factors when doing classProbs in training
   
   
   n_partitions <- switch(method, 
                          'rf' = 1,                                                       # random forest uses a single validation set,
                          'boost' = 2)                                                    # and AdaBoost uses a test and a validation set
   parts <- createDataPartition(x$subclass, p = holdout, times = n_partitions)            # create holdout sets
   
   training <- x[-unlist(parts), ]
   validate <- x[parts[[1]], ]
   if(method == 'boost')
      test <- x[parts[[2]], ]
   
   
   
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
   message(length(levels(training$subclass)) - t, ' levels dropped because of missing values')
   
   model <- reformulate(names(training)[-1], 'subclass')
   
   message('Training set has ', dim(training)[2] - 1, ' predictor variables and ', dim(training)[1], ' cases')
   
   a <- Sys.time()
   z <- train(model, data = training, method = meth, trControl = control, num.threads = 0, importance = 'impurity')             #---train the model
   #    z <- train(model, data = training, method = meth, trControl = control, num.threads = 0, importance = 'impurity', tuneGrid = expand.grid(.mtry = 1, .splitrule = 'gini', .min.node.size = c(10, 20)))
   
   message('Elapsed time for training = ',  as.duration(round(interval(a, Sys.time()))))
   
   
   
   ########### From here on down, move everything to assess
   
   
   import <- varImp(z)
   import$importance <- import$importance[order(import$importance$Overall, decreasing = TRUE), , drop = FALSE][1:top_importance, , drop = FALSE]
   plot(import)
   
   validate <- validate[complete.cases(validate), ]
   validate$subclass <- droplevels(validate$subclass)
   y <- stats::predict(z, newdata = validate)
   
   confuse <- confusionMatrix(validate$subclass, y)
   kappa <- confuse$overall['Kappa']                                             # can pull stats like this
   
   cat('\n')
   print(confuse)
   
   
   the$fit$fit <- z                                                              # save most recent fit
   the$fit$pred <- y
   the$fit$train <- train
   the$fit$validate <- validate
   the$fit$confuse <- confuse
   the$fit$import <- import
   
   ts <- stamp('2025-Mar-25_13-18', quiet = TRUE)                                # and write to an RDS (this is temporary; will include in database soon)
   f <- file.path(the$modelsdir, paste0('fit_', sites[1], '_', ts(now()), '.RDS'))# ***************** temporary!! 
   saveRDS(the$fit, f)
   message('Fit saved to ', f)
   
}
