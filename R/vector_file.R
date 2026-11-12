#' Find a vector file, preferring GeoPackage over shapefile
#'
#' Internal vector files (footprints, transects, blocks) are written as GeoPackages, but older
#' runs and hand-made files may be shapefiles. This returns `<dir>/<base>.gpkg` if it exists,
#' otherwise `<dir>/<base>.shp`.
#'
#' @param dir Directory
#' @param base File name without extension, e.g., `NOR_transects`
#' @param must_exist If TRUE, throw an error if neither exists; if FALSE, return the `.gpkg` path
#'    (the one we'd write)
#' @returns Path to the vector file
#' @keywords internal


vector_file <- function(dir, base, must_exist = TRUE) {


   f <- file.path(dir, paste0(base, c('.gpkg', '.shp')))
   if(file.exists(f[1]))
      return(f[1])
   if(file.exists(f[2]))
      return(f[2])
   if(must_exist)
      stop('Vector file not found: ', file.path(dir, base), '.gpkg (or .shp)')
   f[1]
}



#' Read a single-layer vector file (GeoPackage or shapefile)
#'
#' Throws an error for GeoPackages with more than one layer, rather than letting `st_read`
#' quietly pick the first.
#'
#' @param path Path to `.gpkg` or `.shp`
#' @param ... Additional arguments passed to `st_read`
#' @returns `sf` object
#' @importFrom sf st_read st_layers
#' @keywords internal


read_vector <- function(path, ...) {


   if(grepl('\\.gpkg$', path, ignore.case = TRUE)) {
      layers <- st_layers(path)$name
      if(length(layers) != 1)
         stop(path, ' has ', length(layers), ' layers (', paste(layers, collapse = ', '),
              '); it must have exactly one')
   }
   st_read(path, quiet = TRUE, ...)
}



#' Write a vector file as a GeoPackage, replacing any existing file
#'
#' The whole file is replaced (`delete_dsn = TRUE`), so we never end up with mixed-layer
#' GeoPackages. If the existing file is locked (generally because it's open in ArcGIS or QGIS),
#' we pause and ask you to close it in an interactive session, or throw an error in batch mode.
#'
#' @param x `sf` object
#' @param path Path to `.gpkg`
#' @importFrom sf st_write
#' @keywords internal


write_vector <- function(x, path) {


   if(!grepl('\\.gpkg$', path, ignore.case = TRUE))
      stop('write_vector writes GeoPackages only: ', path)

   locked <- function() {                                                               # complain about locked file
      msg <- paste0('\n\n   ********** LOCKED FILE: ', path, ' **********\n',
                    '   Close ArcGIS/QGIS (or whatever has it open)')
      if(!interactive())
         stop(msg, ' and rerun.')
      readline(paste0(msg, ' and hit return... '))
   }

   repeat {
      unlink(paste0(path, c('', '-wal', '-shm', '-journal')))                           # remove the old file and any SQLite droppings
      if(file.exists(path)) {                                                           # if it's still there, it's locked
         locked()
         next
      }
      ok <- tryCatch({
         st_write(x, path, delete_dsn = TRUE, quiet = TRUE)
         TRUE
      },
      error = function(cond) {
         if(!grepl('lock|busy|permission|in use', conditionMessage(cond), ignore.case = TRUE))
            stop(cond)
         FALSE
      })
      if(ok)
         return(invisible(path))
      locked()
   }
}
