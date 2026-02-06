#' Clones a site directory at a new grain
#' 
#' - this is experimental, to see if true rescaling helps
#' - you'll have to add site to sites.txt on your own **before** running this
#' - there is currently no path to use `gather` on the cloned site;
#'   I'll add it if this seems promising
#' - upscaled orthos are not cloned
#' - rejected orthos are not cloned
#' - scores and comments are copied to the new site
#' - this doesn't bother with blocks files
#' - this only affects the `flights` directory. You should be able
#'   to run `screen`, `derive`, `sample`, and other functions
#'   normally after cloning.
#' - I could add `sd` as an option, making multiple results. You can
#'   also specify arbitrary functions, so this would be a good place 
#'   for other upscaling funs.
#' 
#' @param site Site name
#' @param newsite Name for cloned site
#' @param cellsize Cell size for new site (m)
#' @importFrom terra rast datatype res aggregate writeRaster
#' @importFrom tools file_path_sans_ext
#' @export


upscale_clone <- function(site, newsite, cellsize) {
   
   
   source <- resolve_dir(the$flightsdir, site)
   result <- resolve_dir(the$flightsdir, newsite)
   
   if(!dir.exists(result))
      dir.create(result, recursive = TRUE)
   
   
   db_name <- paste0('flights_', site, '.txt')                             # copy flights database and nuke stuff we don't want to keep
   new_db_name <- file.path(paste0('flights_', site, '.txt'))
   db <- read.table(file.path(source, db_name), 
                    sep = '\t', quote = '', header = TRUE)
   db[, c('filestamp', 'pct_missing', 'missing_filestamp')] <- NA
   
   db$window[is.na(db$window)] <- ''
   db$score[is.na(db$score)] <- 0
   db <- db[!db$deleted & nchar(db$window) == 0 & db$score != 1, ]         # we're keeping everything but deleted, upscaled and rejected orthos
   save_flights_db(db, file.path(result, db_name))
   
   orthos <- db$name
   x <- rast(file.path(source, orthos[1]))                                 # get rescaling factor from first raster
   x <- project(x, 'epsg:26986')               # we're already in Mass State Plane now
   factor <- round(cellsize / res(x)[1])                                   # integer rescaling factor
   message('Rescaling factor = ', factor)
   
   for(i in seq_along(orthos)) {                                           # for each ortho,
      message('Processing ', orthos[i], ' (', i, ' of ', length(orthos), ')...')
      
      x <- rast(file.path(source, orthos[i]))                              #    read raster
      type <- datatype(x, bylyr = FALSE)                                   #    get datatype and missing
      missing <- get_NAflag(x) 
      
      x <- terra::aggregate(x, factor, fun = 'mean')                       #    use aggregate to upscale
      writeRaster(x, file.path(result, orthos[i]), 
                  overwrite = TRUE, datatype = type, NAflag = missing)     #    save raster
      
      if(i == 1)
         standard <- x
   }
   
   
   shpsource <- resolve_dir(the$shapefilesdir, site)                       # finally, process transects shapefile
   shpresult <- resolve_dir(the$shapefilesdir, newsite)
   
   if(!dir.exists(shpresult))
      dir.create(shpresult, recursive = TRUE)
   
   t <- file.copy(shpsource, dirname(shpresult), recursive = TRUE, overwrite = TRUE)
   
   flights_prep(newsite, cache = FALSE)
   message('Finished upscaling orthos')
   
   
   field <- file.path(resolve_dir(the$shapefilesdir, newsite), paste0(file_path_sans_ext(get_sites(site)$transects), '_final.shp'))
   fieldresult <- resolve_dir(the$fielddir, newsite)
   
   if(!dir.exists(fieldresult))
      dir.create(fieldresult, recursive = TRUE)
   
   suppressWarnings(transects <-
                       rasterize(vect(field), standard, 
                                 field = 'poly')$poly |>                   # convert it to raster populated with unique poly id
                       writeRaster(file.path(fieldresult, 'transects.tif'), 
                                   overwrite = TRUE, datatype = type, 
                                   NAflag = missing))
   
   message('Field datafile created')
}
