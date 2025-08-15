#' Assess a model
#'
#' Called by do_fit, but also may be called by the user. Either provide `fitid` for
#' the model you want to assess (the normal approach), or `model`, `confuse` and  
#' `nvalidate` (the approach used by do_fit, becaue the model is not yet in the database).
#' 
#' You may supply `newdata` to assess a model on sites different from what the model
#' was built on. `newdata` is a data frame that conforms to the data the model was 
#' built on. (***how exactly***?)
#' 
#' Assessments are returned invisibly; they may also be printed (or plotted) via
#' options.
#' 
#' *** Insert explanation of stats from prelim_rf_resuls.Rmd ***
#'
#' @param fitid id of a model in the fits database. If using this, omit `model` and 
#'    `validate`, as these will be extracted from the database.
#' @param model Model object 
#' @param nvalidate Number of cases in validation set
#' @param newdata An alternate validation set (e.g., from a different site). Variables
#'    must conform with the original dataset.
#' @param summary Print model summary info if TRUE
#' @param confusion Print the confusion matrix if TRUE, and skip if FALSE
#' @param importance Print variable importance if TRUE, plot it if 'plot', and skip printing (but still return) if FALSE
#' @returns
#' @importFrom stats predict
#' @export


assess <- function(fitid = NULL, model = NULL, confuse = NULL, nvalidate = NULL, newdata = NULL,
                   summary = TRUE, confusion = TRUE, importance = TRUE) {
   
   
   if(!is.null(fitid)) {
      # ********************* set model, confuse, and nvalidate from fit database ***************
   }
   
   if(!is.null(newdata)) {                                           # if new data have been passed,
      y <- stats::predict(model, newdata = newdata)                  #    we'l work with it
      confuse <- help(newdata$subclass, y)
   }
   
   info <- paste0('Model [model name and id]')
   info <- paste0(info, '\n', dim(model$train)[2], ' variables')
   info <- paste0(info, '\nn = ', dim(model$train)[1], ' (training), ', nvalidate, ' (validation)')
   info <- paste0(info, '\nCorrect classification rate (CCR) = ', round(confuse$overall['Accuracy'] * 100, 2), '%')  
   info <- paste0(info, '\nKappa = ', round(confuse$overall['Kappa'], 4), '\n\n')
   
   varimp <- varImp(model)
   
   if(summary)
      cat(info)
   
   if(confusion)
      print(confuse)
   
   if(importance) {
      cat('\n')
      print(varimp)
   }
   
   invisible(list(summary = info, confusion = confuse, importance = varimp))
}