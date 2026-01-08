#' Repair mixed POSIXct/numeric vectors
#' 
#' I don't know how these happen, but they keep showing up. Strings look like this
#' ```
#' "2025-10-04 01:22:44.55288"  "2025-10-04 01:22:44.55288"  "1767713663.71366"  "1767713663.71366" 
#' ```
#' @param x Vector that should all be POSIXct
#' @returns Vector that all is POSIXct
#' @keywords internal


fix_POSIXct <- function(x) {
   
   
   b <- !is.na(suppressWarnings(as.numeric(x)))
   x[b] <- as.character(as.POSIXct(as.numeric(x[b])))
   x
}