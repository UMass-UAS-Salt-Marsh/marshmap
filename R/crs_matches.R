#' Does a spatial object's horizontal CRS match a target CRS?
#'
#' Compares only the horizontal component, as `authority:code`, so a compound CRS such as
#' `EPSG:6491+5703` (NAD83(2011) / Massachusetts Mainland + NAVD88 height) matches `EPSG:6491`.
#' That's what matters for clipping, resampling, and rasterizing; we never transform vertical
#' datums here.
#'
#' @param x An `sf`, `sfc`, `crs`, `SpatRaster`, or `SpatVector` object, or a CRS string
#' @param target Target CRS string, e.g., `EPSG:6491+5703` or `EPSG:26986`
#' @returns TRUE if the horizontal CRS of `x` matches that of `target`
#' @importFrom sf st_crs
#' @keywords internal


crs_matches <- function(x, target) {


   horiz_crs(x) == horiz_crs(target)
}



#' Horizontal CRS of a spatial object as `authority:code`
#'
#' @param x An `sf`, `sfc`, `crs`, `SpatRaster`, or `SpatVector` object, or a CRS string
#' @returns Horizontal CRS as a string, e.g., `EPSG:6491`
#' @importFrom sf st_crs
#' @keywords internal


horiz_crs <- function(x) {


   w <- if(inherits(x, c('sf', 'sfc', 'crs')))
      st_crs(x)$wkt
   else if(is.character(x))
      x
   else
      terra::crs(x)

   d <- terra::crs(w, describe = TRUE)
   paste(d$authority, d$code, sep = ':')
}
