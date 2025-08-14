#' Fit models
#' 
#' @param site Site name (potentially a metasite for multi-site models); determines path 
#'    of data. Default = `the$site`; must be set here if `the$site` is NULL. `the$site` 
#'    will be set by the first call of `fit`; it may also be set directly.
#' @param datafile Name of data file. Extension `.RDS` must be included. Default = 
#'    `the$datafile`, or `data.RDS` if `the$datafile` is NULL.
#' @param method One of `rf` for Random Forest, `boost` for AdaBoost. Default = `rf`.
#' @param vars An optional vector of variables to restrict analysis to. Default = NULL, 
#'    all variables.
#' @param exclude An optional vector of variables to exclude.
#' @param years An optional vector of years to restrict variables to.
#' @param maxmissing Maximum proportion of missing training points allowed before a 
#'    variable is dropped.
#' @param top_importance Give number of variables to keep for variable importance.
#' @param reread If TRUE, forces reread of datafile.
#' @param holdout Proportion of points to hold out. For Random Forest, this specifies 
#'    the size of the single validation set, while for boosting, it is the size of each
#'    of the testing and validation sets.
#' @param auc If TRUE, calculate class probabilities so we can calculate AUC.
#' @importFrom caret createDataPartition trainControl train varImp confusionMatrix
#' @importFrom stats complete.cases predict reformulate
#' @importFrom lubridate interval as.duration
#' @importFrom stringr str_extract
#' @export


# OLD FIT - Last good version before rewrite


old_fit <- function(site = the$site, datafile = the$datafile, method = 'rf', 
                vars = NULL, exclude = NULL, years = NULL, maxmissing = 0.05, 
                top_importance = 20, reread = FALSE, holdout = 0.2, auc = TRUE) {
   
   
   cat('THIS IS OLD FIT!\n')
   
   lf <- file.path(the$modelsdir, paste0('fit_', site, '.log'))                     # set up logging
   
   if(is.null(site) & is.null(the$site))
      stop('Site name isn\'t already specified; it must be set with the site option')
   
   if(is.null(site))
      site <- the$site
   
   if(is.null(datafile))
      datafile <- the$datafile
   
   
   reread <- reread | is.null(the$site) || site != the$site                         # reread data if this is a new site
   reread <- reread | is.null(the$datafile) || datafile != the$datafile             # or a new datafile
   reread <- reread | is.null(the$data)                                             # or if we don't have data yet
   
   if(reread) {                                                                     # if reading or rereading the datafile,
      the$data <- NULL
      the$site <- site                                                              #    read data and set the$site, the$datafile, and the$data
      if(is.null(datafile))
         datafile <- 'data.RDS'
      the$datafile <- datafile
      
      df <- file.path(resolve_dir(the$samplesdir, tolower(site)), the$datafile)
      if(!file.exists(df))
         stop('Datafile ', df, ' does not exist')
      
      msg(paste0('Reading datafile ', datafile, ' for site ', site, '...'), lf)
      x <- readRDS(df)                                                              # *** could add option to read .txt, add .RDS if need be, error if missing file
      x$subclass <- as.factor(x$subclass)
      the$data <- x
   }
   else 
      x <- the$data
   
   the$datafile <- datafile
   
   msg('', lf)
   msg(paste0('Fitting for site = ', site, ', datafile = ', datafile), lf)
   
   
   
   if(!is.null(vars)) {                                                             # if restricting to selected variables,
      x <- x[, names(x) %in% c('subclass', vars)]
      msg(paste0('Analysis limited to ', length(names(x)) - 1, 
                 ' selected variables'), lf)
   }
   
   
   if(!is.null(exclude)) {                                                          # if excluding variables,
      x <- x[, !names(x) %in% exclude]                                              
      msg(paste0('Analysis limited to ', length(names(x)) - 1, 
                 ' variables after exclusions'), lf)
   }
   
   if(!is.null(years)) {                                                            # if restricting to selected years,
      d <- stringr::str_extract(names(x), '^X*\\d+[a-zA-Z]{3}\\d+_') |>             #    extract substring with year
         stringr::str_extract('\\d+_') |>                                           #    and year with underscore                                          
         sub(pattern = '_', replacement = '') |>
         as.numeric()
      d <- d + (d < 2000) * 2000
      d <- d %in% years 
      x <- x[, c(TRUE, d[-1])]
      msg(paste0('Analysis limited to ', length(names(x)) - 1, ' variables by year'), lf)
   }
   
   
   x <- x[, c(TRUE, colSums(is.na(x[, -1])) / dim(x)[1] <= maxmissing)]             # drop variables with too many missing values
   
   if(auc)                                                                          # if preparing data for AUC, 
      x$subclass <- as.factor(paste0('class', x$subclass))                          #    we can't use numbers for factors when doing classProbs in train
   
   n_partitions <- switch(method, 
                          'rf' = 1,                                                 # random forest uses a single validation set,
                          'boost' = 2)                                              # and AdaBoost uses a test and a validation set
   parts <- createDataPartition(x$subclass, p = holdout, times = n_partitions)      # create holdout sets
   
   train <- x[-unlist(parts), ]
   validate <- x[parts[[1]], ]
   if(method == 'boost')
      test <- x[parts[[2]], ]
   
   
   
   switch(method, 
          'rf' = {
             meth <- 'ranger'
             if(auc)                                                                #    if prepping for AUC,
                control <- trainControl(method = "cv",                              #       add necessary items to train control  ***** check these--are they all needed here??????
                                        number = 5,
                                        classProbs = TRUE,
                                        savePredictions = "final"
                )
             else                                                                   #    else,
                control <- trainControl(allowParallel = TRUE)                       #       controls for random forests, no AUC
          },
          'boost' = {
             meth <- 'adaboost'
             control <- trainControl()                                              # conrols for AdaBoost
          }
   )  
   
   # tuning ...
   
   train <- train[complete.cases(train), ]                        # wtf?
   # na.action = 'na.omit' fails, but na.learn fails. Maybe impute values? Some vars are missing for half of site. Some subclasses have no complete rows.
   # all I can make work so far is using complete cases
   # train <- train[!train$subclass %in% c(7, 10, 11, 26, 33), ]     # try this. Nope.
   
   
   t <- length(levels(train$subclass))
   train$subclass <- droplevels(train$subclass)
   msg(paste0(length(levels(train$subclass)) - t, ' levels dropped because of missing values'), lf)
   
   model <- reformulate(names(train)[-1], 'subclass')
   
   msg(paste0('Training set has ', dim(train)[2] - 1, ' predictor variables and ', dim(train)[1], ' cases'), lf)
   
   a <- Sys.time()
   z <- train(model, data = train, method = meth, trControl = control, num.threads = 0, importance = 'impurity')             #---train the model
   #    z <- train(model, data = train, method = meth, trControl = control, num.threads = 0, importance = 'impurity', tuneGrid = expand.grid(.mtry = 1, .splitrule = 'gini', .min.node.size = c(10, 20)))
   
   msg(paste0('Elapsed time for training = ',  as.duration(round(interval(a, Sys.time())))), lf)
   
   
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
   f <- file.path(the$modelsdir, paste0('fit_', the$site, '_', ts(now()), '.RDS'))
   saveRDS(the$fit, f)
   msg(paste0('Fit saved to ', f), lf)
   
}
