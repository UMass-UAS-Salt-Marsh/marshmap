#' Saves the flights database
#' 
#' @param db Database table
#' @param db_name Path and name of database file
#' @keywords internal


save_flights_db <- function(db, db_name) {
   
   
   if(!is.null(db))
      if(0 < length(db$score))
         write.table(db, db_name, sep = '\t', quote = FALSE, row.names = FALSE, na = '')
   
}
