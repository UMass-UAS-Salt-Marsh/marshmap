#' Purge selected fits from fits database
#' 
#' @param rows Selected rows in the fits database. Use one of
#'  - a vector of `fitids`
#'  - 'all' for all fits
#'  - a named list to filter fits. List items are `<field in fdb> = <value>`, 
#'    where `<value>` is a regex for character fields, or an actual value (or vector of 
#'    values) for logical or numeric fields.
#' @export


fitpurge <- function(rows) {
   
   
   load_database('fdb')                                                                # Get fits database
   
   if(dim(the$fdb)[1] == 0) {
      message('No fits in database')
      return(invisible())
   }
}