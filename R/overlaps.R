#' Erase overlapping polys where class field isn't equal
#' 
#' @param polys sf object with potential multipolys
#' @param field Field to check for overlaps
#' @returns New sf object with overlaps erased unless all values in field are equal
#' @importFrom sf st_intersection
#' @keywords internal


overlaps <- function(polys, field) {
   
   
   x <- st_intersection(polys)                                                   # intersect shapefile with itself                                     
   b <- sapply(x$origins, function(i) length(unique(polys[i, field])) == 1)      # TRUE if all overlaps are equal
   z <- x[b, ]                                                                   # keep these
   
   z
}