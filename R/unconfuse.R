#' Clean up confusion matrix and associated stats
#' 
#' Cleans up the confusion matrix from a caret/ranger model fit:
#' - If class names are numeric:
#'   - include only the number in the confusion matrix and sort numerically
#'   - change the labels to `Class <number>` in the `byClass` table and sort
#'     numerically
#' - Round the `byClass` table to 4 digits, which is more than plenty!
#' - Optionally add a row for AUC to the `byClass` table. If the model hasn't been
#'   run with the necessary data for AUC, a message will be displayed and the
#'   row won't be added.
#' 
#' Print the resulting table with `print(confuse, mode = 'prec_recall')`.
#' 
#' @param confuse Confusion matrix
#' @param auc If TRUE, add AUC to the `byClass` table
#' @param fit A `ranger` model object (only needed if `auc` = TRUE)
#' @returns A new model object with the confusion matrix cleaned up
#' @keywords internal


unconfuse <- function(confuse, auc = TRUE, fit = NULL) {
   
   
   classes <- colnames(confuse$table)
   if(length(grep('\\d$', classes)) == length(classes)) {                        # if class names all end in numbers
      n <- as.numeric(sub('[a-zA-Z]*(\\d+)$', '\\1', classes))                   #    pull the numbers
      s <- order(n)
      
      colnames(confuse$table) <- n                                               #    use numbers for names in confusion matrix
      rownames(confuse$table) <- n
      confuse$table <- confuse$table[s, s]                                       #    and sort it numerically
      
      if(!is.null(confuse$byClass)) {                                            #    don't crash if there's only one class
         rownames(confuse$byClass) <- paste0('Class ', n)                        #    use numbers in byClass table
         confuse$byClass <- confuse$byClass[s, ]
      }
   }
   
   confuse$byClass <- round(confuse$byClass, 4)
   
   if(auc)
      if(!is.null(auc <- aucs(fit, sort = FALSE)))
         confuse$byClass <- cbind(confuse$byClass, AUC = auc)
   
   confuse
}