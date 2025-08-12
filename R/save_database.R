#' Save the specified database 
#' 
#' Saves the database in directory `the$dbdir`. Previous versions are renamed e.g., `fdb_1.RDS`,
#' `fdb_2.RDS`, etc. Will need a mechanism to delete databases more than a week old (or something).
#' 
#' For the model fit database, `fdb`, `the$last_fit_id` is written to `last_fit_id.txt` to track
#' the highest fit id used, as these ids are *never* reused.
#' 
#' @param database Name of database (should be `fdb` for the model fit database, or 
#'    `mdb` for the map database)
#' @importFrom tools file_path_sans_ext
#' @export


save_database <- function(database) {
   
   
   if(is.null(the[[database]]))                                                              # if don't have the database, throw an error 
      stop('Database ', database, ' isn\'t loaded, so it can\'t be saved')
   
   if(!dir.exists(the$dbdir))                                                                # create database directory if it doesn't exist yet
      dir.create(the$dbdir, recursive = TRUE)
   
   if(file.exists(f <- file.path(the$dbdir, paste0(database, '.RDS')))) {                    # if a saved version already exists, 
      if(identical(the[[database]], readRDS(f)))                                             #    and it's identical to what we've got
         return(invisible())                                                                 #       we're done
      else {                                                                                 #    else, rename it as a backup
         l <- file_path_sans_ext(list.files(the$dbdir, pattern = database))                  #       database filenames
         n <- max(c(0, as.numeric(sub(paste0(database, '_*'), '', l))), na.rm = TRUE) + 1    #       backup file number
         file.rename(f, file.path(the$dbdir, paste0(database, '_', n, '.RDS')))
      }
   }
   
   saveRDS(the[[database]], f)
   
   if(database == 'fdb') {                                        # if saving the model fit database,
      f <- file.path(the$dbdir, 'last_fit_id.txt')                #    save the last fit id
      writeLines(the$last_fit_id, f)
   }
   
}