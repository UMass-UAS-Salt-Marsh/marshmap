#' Give the area of a clip vector
#' 
#' @param clip Vector of `xmin`, `xmax`, `ymin`, `ymax`
#' @param units Area units to return
#' @param crs Coordinate reference system of clip
#' @importFrom terra ext as.polygons crs<- project expanse
#' @keywords internal


extent_area <- function(clip, units = 'ha', crs = 'epsg:4326') {
   
   
   x <- as.polygons(ext(clip))
   crs(x) <- crs
   expanse(project(x, 'epsg:4326'), unit = units)
}