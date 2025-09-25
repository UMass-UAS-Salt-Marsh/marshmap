#' Prepare flights data after `gather`
#' 
#' Run by `gather`, this 
#' 1. Gets percent missing for each ortho (checks for updated orthos from
#'    missing_filestamp in flights database)
#' 2. Makes a raster of number of orthos with a missing value in each cell
#'    (redoes this if any orthos change)
#' 3. Gets number of bands for each ortho
#' 4. Caches images for `screen` (checks to see if images are outdated with
#'    respect to orthos)
#' The flights database is updated accordingly.
#'
#' @param site site, using 3 letter abbreviation
#' @importFrom terra rast setValues writeRaster
#' @importFrom rasterPrep makeNiceTif assessType
#' @importFrom lubridate now
#' @keywords internal

flights_prep <- function(site) {
   
   
   message('\nRunning flights_prep...')
   
   db <- build_flights_db(site)                                         # update flights database
   
   dir <- resolve_dir(the$flightsdir, site)
   fd <- file.mtime(file.path(dir, db$db$name))                         # file dates on disk
   update <- is.na(db$db$missing_filestamp) |
      db$db$missing_filestamp < fd                                      # files that are new or outdated,
   
   
   if(any(update)) {                                                    # if any files have been updated, we have to read them all
      
      message('Updating missing value counts for ', 
              sum(update), ' orthos and all_miss raster...')
      
      
      sites <- read_pars_table('sites')    
      fp <- basename(sites$footprint[sites$site == site])
      footprint <- vect(file.path(resolve_dir(the$shapefilesdir, site), fp))
      
      for(i in seq_len(nrow(db$db))) {                                  #    for each ortho,
         
         print(i)
         
         x <- rast(file.path(dir, db$db$name[i]))[[1]]                  #       read raster (* we assume NAs are shared across all bands)
         if(i == 1) {                                                   #       if first one,
            fp <- global(mask(setValues(x, 1), footprint), 
                         'sum', na.rm = TRUE)                           #          count of cells in footprint
            all_miss <- setValues(x, 0)                                 #          create missing raster
         }
         
         all_miss <- all_miss + is.na(x)                                #       and count missing
         
         if(update[i]) {                                                #       if this file needs updating,
            db$db$pct_missing[i] <- 
               (global(!is.na(x), 'sum')) / fp * 100                    #          get percent missing
            db$db$bands <- nlyr(rast(file.path(dir, db$db$name[i])))    #          get number of bands
         }
      }
      
      db$db$missing_filestamp[update] <- now()                          # update missing_filestamp
      
      rd <- resolve_dir(the$reportsdir, site)
      all_miss <- mask(all_miss, footprint)
      am <- file.path(rd, paste0('all_miss_', toupper(site)))
      
      writeRaster(all_miss, paste0(am, '000.tif'), overwrite = TRUE,
                  datatype = 'INT2S', 
                  NAflag = assessType('INT2S')$noDataValue)             # save all_miss, count of missing values in all rasters
      
      makeNiceTif(source = paste0(am, '000.tif'), 
                  destination = paste0(am, '.tif'), 
                  overwrite = TRUE,                               
                  overviewResample = 'average', stats = TRUE)           # make a nice TIFF
      
      unlink(paste0(am, '000.*'))
   }
   else
      message('Missing value counts are all up-to-date')
   
   save_flights_db(db$db, db$db_name)
}