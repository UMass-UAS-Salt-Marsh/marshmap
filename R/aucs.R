#' Return multi-class AUC (Area Under the Curve) for ranger models from caret
#' 
#' To use this, you must do the following when training the model:
#' - Class names must be valid R variables, so not 1, 2, 3, ... They must still
#'   be factors.
#' - You'll need to supply the `trControl` option to train with the following:
#'   `control <- trainControl(` \cr
#'   `   allowParallel = TRUE,` \cr
#'   `   method = 'cv',` \cr
#'   `   number = 5,` \cr
#'   `   classProbs = TRUE,` \cr
#'   `   savePredictions = 'final'` \cr
#'   `)`
#'   
#' If class levels all end in numbers (e.g., `class1`, `class`, `class3`), the 
#' result will be sorted by the numbers so you won't get crap like `class1`, 
#' `class10`, `class100`.
#'   
#' @param fit Model fit from `train`
#' @param sort If TRUE, sort classes by trailing number
#' @returns A vector with the AUC for each class
#' @importFrom pROC auc
#' @importFrom stats setNames
#' @keywords internal


aucs <- function(fit, sort = TRUE) {
   
   if(is.null(names(fit$pred))) {
      message('Skipping AUC, as model doesn\'t have necessary data')
      return(NULL)
   }
   
   
   levels <- levels(fit$trainingData$.outcome)
   z <- setNames(numeric(length(levels)), levels)
   
   for(cl in levels) {                                                     # for each class,
      true_bin <- as.numeric(fit$pred$obs == cl)
      z[cl] <- suppressMessages(pROC::auc(true_bin, fit$pred[[cl]]))
   }
   
   if(length(grep('\\d$', names(z))) == length(z)) {                       # if class names all end in numbers
      s <- order(as.numeric(sub('[a-zA-Z]*(\\d+)$', '\\1', names(z))))     #    sort them properly
      z <- z[s]
   }
   
   z
}