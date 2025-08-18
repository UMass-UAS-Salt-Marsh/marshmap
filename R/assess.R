#' Assess a model
#'
#' Called by do_fit, but also may be called by the user. Either provide `fitid` for
#' the model you want to assess (the normal approach), or `model`, a list with necessary
#' arguments (the approach used by do_fit, becaue the model is not yet in the database).
#' 
#' You may supply `newdata` to assess a model on sites different from what the model
#' was built on. `newdata` is a data frame that conforms to the data the model was 
#' built on. (***how exactly***?)
#' 
#' Assessments are returned invisibly; by default, they are printed to the console.
#' 
#' **Explanations**
#' 
#' ***1. Model info***
#' - Model fit id and name, if supplied
#' - Number of variables fit
#' - Sample size for training and validation holdout set. The confusion matrix and all statistics are 
#'   derived from the holdout set.
#' - Correct classification rate, the percent of cases that were predicted correctly.
#' - Kappa, a refined version of the CCR that takes the probability of chance agreement into account.
#' 
#' ***2. Confusion matrix***
#' - Shows which classification errors were made. Values falling on the diagonal were predicted correctly. 
#'   
#' ***3. Overall statistics***
#' - *Accuracy* is the correct classification rate (also known as CCR), the percent of cases that fall on 
#'   the diagonal in the confusion matrix.
#' - The *No Information Rate* is the CCR you'd get if you always bet the majority class. 
#' - *Kappa* is a refined version of the CCR that takes the probability of chance agreement into account.
#' - *Mcnemar's test* only applies to two-class data.
#' 
#' ***4. Statistics by class***
#' - Lists the follwing statistics for each of the subclasses.
#'   These all scale from 0 to 1, with 1 generally indicating higher performance (except for prevalence, 
#'   detection rate, and detection prevalence).
#'   
#'   - *Precision*, the proportion of cases predicted to be in the class that actually were (true positives / 
#'     (true positives + false positives))
#'   - *Recall*, the proportion of cases actually in the class that were predicted to be in the class (true positives / 
#'     (true positives + false negatives))
#'   - *F1*, the harmonic mean of precision and recall; a combined metric of model performance
#'   - *Prevalence*, the proportion of all cases that are in this class
#'   - *Detection Rate*, the proportion of all cases that are correctly predicted to be in this class
#'   - *Detection Prevalence*, the proportion of all cases predicted to be in this class
#'   - *Balanced Accuracy*, mean of true positive rate and true negative rate; a combined metric of model performance
#'   - *AUC* (Area Under the Curve) is the probability that the model, for a particular class, when given a 
#'     random case in the class and a random case from another class, will rate the case in the class higher. 
#'     Unlike the other statistics, AUC is independent of the particluar cutpoint chosen, and is telling us
#'     about the performance of the probabilities produced by the model.
#'     
#' ***5. Variable importance***
#' - Scaled from 0 to 100, gives the relative contribution of each variable to the model fit. Less-important variables
#'   will be trimmed based on the top_importance option. Note that variables are imagery bands, not an entire orthoimage;
#'   thus, for instance, an RGB true color image represents three varaibles, any of which may come into the model separately.
#' 
#' @param fitid id of a model in the fits database. If using this, omit `model`, as 
#' this info will be extracted from the database.
#' @param model Only when called by do_fit; named list of:
#'  \describe{
#'    \item{fit}{model fit oject}
#'    \item{confuse}{Confusion matrix}
#'    \item{nvalidate}{Number of cases in validation set}
#'    \item{id}{Model id}
#'    \item{name}{Model name}
#'  }
#' @param newdata An alternate validation set (e.g., from a different site). Variables
#'    must conform with the original dataset.
#' @param top_importance Number of variables to keep for variable importance
#' @param summary Print model summary info if TRUE
#' @param confusion Print the confusion matrix and complete statistics if TRUE, and skip if FALSE
#' @param importance Print variable importance if TRUE, and skip printing if FALSE
#' @returns Invisibly, a named list of
#'   \describe{
#'     \item{summary}{Model id, name, and topline statistics}
#'     \item{confusion}{Confusion matrix and complete statistics}
#'     \item{importance}{Variable importance data frame}
#'  }
#' @importFrom stats predict
#' @export


assess <- function(fitid = NULL, model = NULL, newdata = NULL,
                   top_importance, summary = TRUE, confusion = TRUE, importance = TRUE) {
   
   
   if(!is.null(fitid)) {
      # ********************* set model, confuse, and nvalidate from fit database ***************
      # model <- list(...)
   }
   
   confuse <- model$confuse
   
   if(!is.null(newdata)) {                                           # if new data have been passed,
      y <- stats::predict(model, newdata = newdata)                  #    we'l work with it
      confuse <- help(newdata$subclass, y)
   }
   
   info <- paste0('Model ', model$id, ifelse(nchar(model$name) > 0, paste0(' (', model$name, ')'), ''))
   lines <- strrep('-', nchar(info))
   info <- paste('\n', lines, info, lines, sep = '\n')
   info <- paste0(info, '\n', dim(model$fit$train)[2], ' variables')
   info <- paste0(info, '\nn = ', dim(model$fit$train)[1], ' (training), ', model$nvalidate, ' (validation)')
   info <- paste0(info, '\nCorrect classification rate (CCR) = ', round(confuse$overall['Accuracy'] * 100, 2), '%')  
   info <- paste0(info, '\nKappa = ', round(confuse$overall['Kappa'], 4), '\n\n')
   
   varimp <- varImp(model$fit)$importance
   names(varimp) <- 'Importance'
   varimp <- varimp[order(varimp$Importance, decreasing = TRUE), , drop = FALSE][1:min(top_importance, nrow(varimp)), , drop = FALSE]
   varimp <- round(varimp, 2)
   
   if(summary)
      cat(info)
   
   if(confusion)
      print(confuse)
   
   if(importance) {
      cat('\nVariable importance\n')
      print(varimp)
   }
   
   invisible(list(summary = info, confusion = confuse, importance = varimp))
}