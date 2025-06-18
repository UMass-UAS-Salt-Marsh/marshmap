#' Produce a zoomed crop into the center of a terra object
#' 
#' @param x A terra object
#' @param factor Proportion of image to include
#' @importFrom terra ext crop
#' @keywords internal


center_zoom <- function(x, factor) {
   
   
   range <- (ext(x)[c(2, 4)] - ext(x)[c(1, 3)])
   center <- ext(x)[c(1, 3)] + range * 0.5
   ce <- c((center - range * factor), (center + range * factor))[c(1, 3, 2, 4)]
   crop(x, ce)
}
