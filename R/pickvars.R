#' pick variables based on importance >= n
#' 
#' @param n Cutoff value for variable importance.
#' @param importance Variable importance object from `fit` 
#' @keywords internal


pickvars <- function(n, importance = the$fit$import) {
   
   
   row.names(importance$importance)[importance$importance >= n]
   
}