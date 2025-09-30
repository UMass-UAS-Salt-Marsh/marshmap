#' Create cached images of orthophotos for display in `screen`
#' 
#' @param cache File name to write cache to
#' @param extent Extent of image; one of `full`, `inset1`, or `inset2`
#' @param pixels Maximum resolution in pixels
#' 

########### a start on this. Need to create insets with center_zoom here and NOT CALL IT ANYWHERE ELSE!!!


flights_image <- function(cache, extent, pixels = 1200) {
   
   
   pixels <- 1200                                         # maximum extent in pixels - sets max image resolution
   if(extent == 'full') {
      s <- c(ncol(data), nrow(data))
      size <- s / max(s) * pixels
   }
   else
      size <- pixels / rep(2, 2)
   
   png(cache, width = size[1], height = size[2])
}