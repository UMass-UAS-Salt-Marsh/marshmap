#' Purge selected fits from fits database
#' 
#' Purged rows in the fits database are saved to `databases/purged/fdb_purged.RDS`, and 
#' associated files are moved to `database/purged/`.
#' 
#' @param rows Selected rows in the fits database. Use one of
#'  - an empty string doesn't purge any fits, but does purge stray fit files
#'  - a vector of `fitids`
#'  - a named list to filter fits. List items are `<field in fdb> = <value>`, 
#'    where `<value>` is a regex for character fields, or an actual value (or vector of 
#'    values) for logical or numeric fields.
#' @param failed If TRUE, all fits where `success` is `FALSE` or `NA` are purged
#' @param undo If TRUE, the previous purge call is reversed, and the database and 
#'    associated files are restored. Call `fitpurge(undo = TRUE)` repeatedly to roll 
#'    back farther.             *** NO, I think use fitpurge(c(1001, 1002, 1003), undo = TRUE) unpurges these jobs ?
#' @export


fitpurge <- function(rows = '', failed = FALSE, undo = FALSE) {
   
   
   if(sum(!is.null(rows), failed, files, undo) > 1)
      stop('You may only supply one of rows, failed, files, and undo')
   
   if(!any(!is.null(rows), failed, files, undo))
      
      
      load_database('fdb')                                                             # Get fits database
   
   if(dim(the$fdb)[1] == 0) {
      message('No fits in database')
      return(invisible())
   }
   
   if(!is.null(rows)) {  
      if(rows == 'all')
         stop('fitpurge(rows = \'all\' is not allowed')
      
      rows <- filter_db(rows, 'fdb')                                                   # fits, filtered
      
      
      # PURGE ROWS
      # pull rows out of fdb.RDS
      # add them to purged/fdb.RDS
      # save both files
      # then move stray files to models/purged/   *** always do this, so fitpurge() purges stray files
      
   } 
   else if(failed) {
      
      # PURGE FAILED - this selects rows

   }
   else if(undo) {
      
      # UNDO
   }
   else
      stop('You must supply one of rows, failed, files, or undo')
   
}