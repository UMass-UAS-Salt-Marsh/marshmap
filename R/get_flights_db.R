#' Get the flights database for a site
#' 
#' @param site A single site name (3 letter code), already vetted
#' @param noerror If TRUE, return NULL instead of error 
#' @returns the flights database, with deleted files excluded
#' @keywords internal


get_flights_db <- function(site, noerror = FALSE) {
   
   
   site <- tolower(site)     
   dir <- resolve_dir(the$flightsdir, site)
   if(!dir.exists(dir)) {
      if(noerror)
         return(NULL)
      else
         stop('There is no flights directory for site ', site)
   }
   db_name <- file.path(dir, paste0('flights_', site, '.txt'))
   if(!file.exists(db_name)) {
      if(noerror)
         return(NULL)
      else
         stop('The flights directory for site ', site, ' hasn\'t been built yet')
   }
   db <- read.table(db_name, sep = '\t', quote = '', header = TRUE)
   db <- db[!db$deleted, ]                                                          # remove deleted files
   
   db$score[is.na(db$score)] <- 0
   
   return(db)
}