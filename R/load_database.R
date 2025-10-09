#' Load the specified database unless we've already got it
#' 
#' Loads the database from directory `the$dbdir` into environment `the`.
#' 
#' For the model fit database, `fdb`, the file `last_fit_id.txt` is read to get model 
#' sequence for empty databases, as these ids are *never* reused. If the file isn't 
#' found, use the max id from `fdb` or 1000 as a last resort, and display a warning.
#' 
#' @param database Name of database (should be `fdb` for the model fit database, or 
#'    `mdb` for the map database)
#' @keywords internal


load_database <- function(database) {
   
   
   f <- file.path(the$dbdir, paste0(database, '.RDS'))
   if(is.null(the[[database]]))                                   # if don't have the database,
      if(!file.exists(f))
         stop('Database ', f, ' doesn\'t exist. Use new_db(\'',database,'\') to create it.')
   
   the[[database]] <- readRDS(f)
   
   if(database == 'fdb') {                                        # if reading the model fit database,
      f <- file.path(the$dbdir, 'last_fit_id.txt')                #    get the last fit id, as these are never reused, even if rows of the database are deleted
      if(file.exists(f))
         the$last_fit_id <- as.numeric(readLines(f))
      else {                                                      #    if there is no last_fit_id.txt,
         the$last_fit_id <- max(the$fdb$id, 1000, na.rm = TRUE)   #       use the max in the database or 1000. This shouldn't happen except early in development.
         warning('last_fit_id.txt not found. Using ', the$last_fit_id, ' as last fit. Make sure fit ids aren\'t being reused!')
      }
   }
}