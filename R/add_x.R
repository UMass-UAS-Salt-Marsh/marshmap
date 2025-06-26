#' Add 'x' to 1st char of filenames that start with a digit
#'
#' This prevents downstream problems
#' 
#' @param x Vector of filenames
#' @returns Filenames with 'x' prepended for those starting with a digit
#' @keywords internal


add_x <- function(x) {
   
   
   i <- grep('^\\d', x)
   x[i] <- paste0('x', x[i])
   x
}
