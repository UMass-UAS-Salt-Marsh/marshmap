#' A wrapper for rast(get_file) that sets missing values to NA
#' 
#' The image geoTIFFs for the Salt Marsh project don't have NAflag set, leading
#' to trouble downstream. This function reads a raster from the Google Drive,
#' SFTP, or local drive, and if NAflag isn't set, comes up with an NAflag based
#' on the data type of the raster, (most commonly in our use, 255 for unsigned
#' bytes and 65535 for unsigned 32-bit integers) and sets these values to NA.
#' 
#' See [get_file] for more info.
#'
#' @param name File path and name
#' @param gd Source drive info, named list of 
#' - `dir` - Google directory info, from [get_dir]
#' - `sourcedrive` - which source drive (`local`, `google`, or `sftp`)
#' - `sftp` - list(url, user)
#' - `cachedir` - local cache directory
#' @param logfile Log file, for reporting missing directories (which don't throw an error)
#' @returns list of:
#'    \item{rast}{raster object}
#'    \item{type}{data type of the object}
#'    \item{missing}{NA value of the object}
#' @importFrom terra datatype NAflag
#' @importFrom rasterPrep assessType
#' @keywords internal


get_rast <- function(name, gd, logfile) {
   
   
   x <- rast(get_file(name, gd, logfile))
   type <- datatype(x, bylyr = FALSE)                                   # get datatype
   missing <- get_NAflag(x)                                             # get NAflag if there is one
   
   if(is.na(missing)) {                                                 # if NAflag isn't set,
      missing <- assessType(datatype(x, bylyr = FALSE))$noDataValue     #    set it based on data type
      x <- subst(x, from = na, to = NA, NAflag = missing, 
                 datatype = datatype(x, bylyr = FALSE))                 #    and replace missing values with NA
   }
   
   list(rast = x, type = type, missing = missing)
}
