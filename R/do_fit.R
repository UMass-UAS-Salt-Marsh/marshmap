#' Fit models
#' 
#' @param fitid Fit id in the fits database
#' @param sites Data frame with `site` (3 letter code), `site_name` (long name), and 
#'    `datafile` (resolved path and filename of datafile). Sites, paths, and filenames
#'    are vetted by fit - there's no checking here.
#' @param name Optional model name
#' @param method One of `rf` for Random Forest, `boost` for AdaBoost. Default = `rf`.
#' @param vars Vector of variables to restrict analysis to. Default = `{*}`, 
#'    all variables. `vars` is processed by `find_orthos`, and may include file names, 
#'    portable names, search names and regular expressions of file and portable names.
#' @param exclude_vars An optional vector of variables to exclude. As with `vars`, variables
#'    are processed by `find_orthos`
#' @param exclude_classes Numeric vector of subclasses to exclude
#' @param reclass Vector of paired classes to reclassify, e.g., `reclass = c(13, 2, 3, 4)`
#'    would reclassify all 13s to 2 and 4s to 3, lumping each pair of classes.
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
#' @param blocks An alternative to holding out random points. Specify a named list 
#'    with `block = <name of block column>, classes = <vector of block classes to hold out>`.
#'    Set this up by creating a shapefile corresponding to ground truth data with a variable
#'    `block` that contains integer block classes, and placing it in the `blocks/` directory
#'    for the site. `gather` and `sample` will collect and process block data for you to 
#'    use here.    
#' @param auc If TRUE, calculate class probabilities so we can calculate AUC
#' @param hyper Hyperparameters ***To be defined***
#' @param rep Throwaway argument to make `slurmcollie` happy
#' @importFrom caret createDataPartition trainControl train varImp confusionMatrix
#' @importFrom stats complete.cases predict reformulate
#' @importFrom lubridate interval as.duration stamp now
#' @importFrom stringr str_extract
#' @importFrom dplyr bind_rows
#' @export


do_fit <- function(fitid, sites, name, method, vars, exclude_vars, exclude_classes, 
                   reclass, max_samples, years, minscore, maxmissing, max_miss_train, 
                   top_importance, holdout, blocks, auc, hyper, rep = NULL) {
   
   
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
   
   
   if(!is.null(reclass)) {                                                                # if reclassifying,
      rcl <- matrix(reclass, length(reclass) / 2, 2, byrow = TRUE)
      for(i in nrow(rcl)) {
         r$subclass[r$subclass == rcl[i, 1]] <- rcl[i, 2]
         message('Subclass ', rcl[i, 1], ' reclassified as ', rcl[i, 2])
      }
   }
   
   
   l <- 1:max(r$subclass)                                                                 # make sure all subclasses are represented in factor so value = subclass
   if(auc)                                                                                # if preparing data for AUC, 
      r$subclass <- factor(r$subclass, levels = l, labels = paste0('class', l))           #    we can't use numbers for factors when doing classProbs in training
   else                                                                                   # else, no AUC,
      r$subclass <- factor(r$subclass, levels = l)                                        #    we want subclass to be factor
   
   
   # want to assess how much of a mess we've made by combining sites. I guess we'll drop stuff with too many missing as usual
   # do want to produce a report with % missing for each var, number of vars with >10, 25, 50% missing, stuff like that
   
   
   message('\nFitting for site', ifelse(nrow(sites) != 1, 's', ''), ' = ', paste(sites$site, collapse = ', '))
   
   
   v <- unique(gsub('-', '_', find_orthos(sites$site, vars, 
                                          minscore, maxmissing)$portable))                # portable names from vars (replace dash with underscore to match var names)
   
   if(length(v) == 0)
      stop('No variables are selected')
   
   r <- r[, (sub('_\\d$', '', names(r)) %in% c('site', 'subclass', v)) | 
             grepl('^_', names(r))]                                                       # include only selected vars, site, subclass, and _block vars
   if(vars != '{*}')
      message('Analysis limited to ', sum(!names(r) %in% c('site', 'subclass')), 
              ' selected variables')
   
   
   e <- unique(gsub('-', '_', find_orthos(sites$site, exclude_vars, 
                                          screen = FALSE)$portable))                      # portable names from exclude_vars (don't exclude any!)
   
   if(!is.null(exclude_vars)) {                                                           # if excluding variables,
      r <- r[, !sub('_\\d$', '', names(r)) %in% e] 
      if(exclude_vars != '')
         message('Analysis limited to ', sum(!names(r) %in% c('site', 'subclass')), 
                 ' variables after exclusions')
   }
   
   
   if(is.null(exclude_classes)) {                                                         # if exclude_classes is supplied, use it
      x <- as.numeric(unlist
                      (strsplit(sites$fit_exclude, ',')))                                 #    otherwise, get it from sites.txt
      if(length(x) != 0)
         exclude_classes <- x
   }
   
   if(!is.null(exclude_classes)) {                                                        # if exclude_classes, drop these from dataset
      t <- nrow(r)
      r <- r[!r$subclass %in% exclude_classes, ]
      message('Excluding classes ', paste(exclude_classes, collapse = ', '), '; dropped ', format(t - nrow(r), big.mark = ','), ' cases')
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
   
   
   r <- r[, c(TRUE, colSums(is.na(r[, -1])) / nrow(r) <= max_miss_train)]                 # drop variables with too many missing values
   
   
   if(!is.null(max_samples))                                                              # if max_samples,
      if(dim(r)[1] > max_samples)                                                         #    and dataset is more than max_samples,
         r <- r[base::sample(dim(r)[1], size = max_samples, replace = FALSE), ]           #       subsample points
   
   
   blks <- r[, b <- grepl('^_', names(r))]                                                # pull out any blocks vars
   r <- r[, !b]
   
   
   n_partitions <- switch(method, 
                          'rf' = 1,                                                       # random forest uses a single validation set,
                          'boost' = 2)                                                    # and AdaBoost uses a test and a validation set  
   
   
   if(!is.null(blocks)) {                                                                 # if we're using blocks for holdouts,   ---- doesn't work with AdaBoost yet
      message('Using blocks ', blocks$block, ', classes ', paste(blocks$classes, collapse = ', '), ' for holdout set')
      blocks$block <- paste0('_', sub('^_', '', blocks$block))                            #    be agnostic to leading underscores in block names
      validate <- r[b <- blks[[blocks$block]] %in% blocks$classes, ]                      #    pull out selected blocks for validation and drop block variables
      training <- r[!b, ]
      message('Using block holdouts: ', nrow(training), ' cases in training set and ', nrow(validate), ' cases in validation set')
      if(nrow(validate) == 0 | nrow(training) == 0)
         stop('Block validation leaves 0 cases in set')
   }
   else                                                                                   # else, select holdout sets based on holdout proportion
   {
      parts <- createDataPartition(r$subclass, p = holdout, times = n_partitions)         # create holdout sets
      
      training <- r[-unlist(parts), ]
      validate <- r[parts[[1]], ]
      if(method == 'boost') {
         test <- r[parts[[2]], ]
         message('Using random holdouts: ', nrow(training), ' cases in training set, ', 
                 nrow(validate), ' cases in validation set, and ', 
                 nrow(test), ' cases in test set')
      }
      else
         message('Using random holdouts: ', nrow(training), ' cases in training set and ',
                 nrow(validate), ' cases in validation set')
   }
   
   
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
   
   training <- training[complete.cases(training), ]                                       # only use complete cases   ....................... *** Sep 2025: try dropping this and see if na.action = 'na.learn' works now
   # na.action = 'na.omit' fails, but na.learn fails. Maybe impute values? Some vars are missing for half of site. Some subclasses have no complete rows.
   # all I can make work so far is using complete cases
   # training <- training[!training$subclass %in% c(7, 10, 11, 26, 33), ]     # try this. Nope.
   
   
   t <- length(levels(training$subclass))
   training$subclass <- droplevels(training$subclass)
   if(dropped <- length(levels(training$subclass)) - t > 0)
      message(dropped, ' levels dropped because of missing values')
   
   model <- reformulate(names(training)[-1], 'subclass')
   
   message('Training set has ', dim(training)[2] - 1, ' predictor variables and ', format(dim(training)[1], big.mark = ','), ' cases')
   
   
   a <- Sys.time()
   z <- train(model, data = training, method = meth, trControl = control, num.threads = 0, importance = 'impurity')             #---train the model
   
   ####   z <- train(model, data = training, method = meth, trControl = control, num.threads = 0, , importance = "permutation", local.importance = TRUE)             #---train the model     ***************************** with local importance**********************
   
   #    z <- train(model, data = training, method = meth, trControl = control, num.threads = 0, importance = 'impurity', tuneGrid = expand.grid(.mtry = 1, .splitrule = 'gini', .min.node.size = c(10, 20)))
   
   
   validate <- validate[complete.cases(validate), ]
   validate$subclass <- droplevels(validate$subclass)
   y <- stats::predict(z, newdata = validate)                                             # --- validate the model on the holdout set
   
   
   
   message('Elapsed time for training = ',  as.duration(round(interval(a, Sys.time()))))
   
   
   levs <- union(levels(droplevels(y)), levels(droplevels(validate$subclass)))            # --- confusion matrix. Make sure both groups share factor levels!
   levs <- levs[order(as.numeric(levs))]
   
   valid <- factor(validate$subclass, levels = levs)                                      # validation data
   test <- factor(y, levels = levs)                                                       # predictions
   
   
   confuse <- unconfuse(confusionMatrix(test, valid, mode = 'prec_recall'))
   
   
   f <- assess(model = list(fit = z, confuse = confuse, nvalidate = dim(validate)[1], 
                            id = fitid, name = name, site = sites),
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
   
   
   # --- write info that doesn't fit in a table (and more importantly, is BIG) to fit_<id>_extra.RDS
   
   r <- list()
   
   r$model_object <- z                                                                    # model object
   r$confuse <- f$confusion                                                               # confusion matrix                        
   r$varimp <- f$importance                                                               # variable importance
   
   saveRDS(r, file.path(the$modelsdir, paste0('fit_', fitid, '_extra.RDS')))
   
   message('Model fit finished; results written to temporary and extra files')
}
