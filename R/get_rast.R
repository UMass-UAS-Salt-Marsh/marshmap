#' A wrapper for `rast` that sets missing values to NA
#' 
#' The image geoTIFFs for the Salt Marsh project don't have `NAflag` set, leading
#' to trouble downstream. This function reads a raster from the Google Drive,
#' SFTP, or local drive, and if `NAflag` isn't set, comes up with an `NAflag` based
#' on the data type of the raster, (most commonly in our use, 255 for unsigned
#' bytes and 65535 for unsigned 32-bit integers) and sets these values to NA.
#' 
#' See [get_file] for more info.
#'
#' @param name File path and name
#' @returns list of:
#'    \item{rast}{raster object}
#'    \item{type}{data type of the object}
#'    \item{missing}{NA value of the object}
#' @importFrom terra datatype NAflag
#' @importFrom rasterPrep assessType
#' @keywords internal


get_rast <- function(name) {
   
   
   x <- rast(name)
   type <- datatype(x, bylyr = FALSE)                                   # get datatype
   missing <- get_NAflag(x)                                             # get NAflag if there is one
   
   if(is.na(missing)) {                                                 # if NAflag isn't set,
      missing <- assessType(datatype(x, bylyr = FALSE))$noDataValue     #    set it based on data type
      x <- subst(x, from = missing, to = NA, NAflag = missing, 
                 datatype = datatype(x, bylyr = FALSE))                 #    and replace missing values with NA
   }
   
   list(rast = x, type = type, missing = missing)
}
