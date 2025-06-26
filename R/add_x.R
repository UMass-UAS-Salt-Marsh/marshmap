#' Add 'x' to 1st char of filenames that start with a digit
#'
#' This prevents downstream problems
#' 
#' @param x Vector of filenames
#' @param ignore If TRUE, don't do anything
#' @returns Filenames with 'x' prepended for those starting with a digit
#' @keywords internal


add_x <- function(x, ignore = FALSE) {
   
   
   if(ignore)
      return(x)
   i <- grep('^\\d', x)
   x[i] <- paste0('x', x[i])
   x
}
