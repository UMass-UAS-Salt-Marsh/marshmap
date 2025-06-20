#' Read and update or build a screening database for a site
#'
#' Reads any existing screen_<site>.txt from flights directory for site, 
#' builds it or updates it for new or deleted files, saves the new version,
#' and returns the path/name and table.
#'
#' @param site Site abbreviation
#' @returns A list of
#'    \item{db}{Site database table}
#'    \item{db_name}{Path and name of database table
#' @keywords insternal


build_screen_db <- function(site) {
   
   
   types <- c('Ortho', 'DEM', 'CHM')                                    # image types
   sensors <- c('Mica', 'SWIR', 'DEM', 'CHM')                           # sensor names             
   tides <- c('Low', 'Mid', 'High')                                     # tide stages
   
   
   find_targets <- function(targets, names) {                           # find targets as substrings in names
      z <- rep(NA, length(names))
      for(j in targets) 
         z[grep(j, names)] <- j 
      
      z
   }
   
   
   site <- tolower(site)
   dir <- resolve_dir(the$flightsdir, site)
   
   if(!dir.exists(dir))                                                 # if there's no flights dir, just return NULL
      return(NULL)
   
   db_name <- file.path(dir, paste0('screen_', site, '.txt'))
   
   
   if(file.exists(db_name))                                             # get or make database
      db <- read.table(db_name, sep = '\t', header = TRUE)
   else
      db <- data.frame(
         name = character(),
         type = character(),
         sensor = character(),
         tide = character(),
         season = character(),
         bands = integer(),                                             # bands and coverage are calulated when we load images
         coverage = integer(),
         quality = integer(),                                           # quality and comment are entered by user
         comment = character(),
         deleted = logical()
      )
   
   
   x <- list.files(dir)                                                 # list files
   x <- grep('.tif', x, value = TRUE)                                   # only want TIFFs
   x <- grep('__', x, invert = TRUE, value = TRUE)                      # and no derived variables
   
   db$deleted <- !db$name %in% x                                        # flag deleted files
   
   
   missing <- x[!x %in% db$name]
   if(length(missing) > 0) {                                            # if any new files are missing from the database,
      i <- nrow(db) + seq_len(length(missing))
      db[i, ] <- NA
      
      db$name[i] <- missing
      db$type[i] <- find_targets(types, missing)
      db$sensor[i] <- find_targets(sensors, missing)
      db$tide[i] <- find_targets(tides, missing)
      db$season[i] <- seasons(missing)
      db$quality[i] <- 0                                                # quality starts with 0 = not scored
      db$comment[i] <- ''
   }
   
   db$quality[is.na(db$quality)] <- 0              # ********** temporary, until I've visited all sites 
   
   save_screen_db(db, db_name)
   
   list(db = db, db_name = db_name)
}