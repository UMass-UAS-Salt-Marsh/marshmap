#' Give the area of a clip vector
#'
#' @param clip Vector of `xmin`, `xmax`, `ymin`, `ymax`
#' @param units Area units to return
#' @param crs Coordinate reference system of clip. Pass the CRS from
#'   the relevant raster (e.g., `crs(my_raster)`) to ensure correctness
#'   regardless of the project's coordinate system.
#' @importFrom terra ext as.polygons crs<- expanse
#' @keywords internal


extent_area <- function(clip, units = 'ha', crs) {


   x <- as.polygons(ext(clip))
   crs(x) <- crs
   expanse(x, unit = units)
}
