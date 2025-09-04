#' Erase overlapping polys where class field isn't equal
#' 
#' @param polys sf object with potential multipolys
#' @param field Field to check for overlaps
#' @returns New sf object with overlaps erased unless all values in field are equal
#' @importFrom sf st_intersection st_geometry_type
#' @keywords internal


overlaps <- function(polys, field) {
   
   
   x <- suppressMessages(st_intersection(polys))                                       # intersect shapefile with itself                                     
   b <- sapply(x$origins, function(i) length(unique(polys[[field]][i])) == 1)          # TRUE if all overlaps are equal
   z <- x[b, names(x) != 'origins']                                                    # keep these; don't want origins list
   z <-z[st_geometry_type(z) %in% c("POLYGON", "MULTIPOLYGON"), ]                      # only want polys
   
   z
}