#' Returns the NAflag for a SpatRaster, making one up if it's not defined
#' 
#' @param rast A SpatRaster object
#' @returns The existing or assigned NAflag
#' @keywords internal


get_NAflag <- function(rast) {
   
   
   z <- NAflag(rast)
   if(is.na(z))
      z <- assessType(datatype(rast)[1])$noDataValue
   
   z
}