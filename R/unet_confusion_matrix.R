#' Create confusion matrix from U-Net predictions
#'
#' @param pred_results Results from unet_predict()
#' @returns confusionMatrix object from caret
#' @importFrom caret confusionMatrix
#' @keywords internal


unet_confusion_matrix <- function(pred_results) {
   
   
   if (!requireNamespace('caret', quietly = TRUE)) {
      stop('caret package required. Install with: install.packages("caret")')
   }
   
   cm <- caret::confusionMatrix(
      data = pred_results$predictions,
      reference = pred_results$labels,
      mode = 'prec_recall'
   )
   
   return(cm)
}
