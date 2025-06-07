#' Get the number of bytes in a pixel of a SpatRaster
#' 
#' @param rast A SpatRaster
#' @returns The number of bytes in a pixel
#' @importFrom terra datatype
#' @export


pixel_bytes <- function(rast) {
   
   
   lookup <- data.frame(
      type = c('INT1S', 'INT1U', 'INT2S', 'INT2U', 'INT4S', 'INT4U', 'FLT4S', 'FLT8S'),
      bytes = c(1, 1, 2, 2, 4, 4, 4, 8)
   )
   
   lookup$bytes[match(datatype(rast)[1], lookup$type)]
}