#' Set model scores and comments
#' 
#'  - Any of
#'    ```
#'    fitset(rows = <a single row>, score = <fit score>)
#'    fitset(rows = <a single row>, assess = 'an assessment comment')
#'    fitset(rows = <a single row>, map = 'a map comment')
#'    ```
#'    sets the subjective model fit score, the assessment. comment, or the map
#'    comment. Any of these may be combined in a single call. Note that you can
#'    use `fitset` on multiple fits, but you'll need to use `multiple = TRUE`.
#' 
#' 
#' @param rows Selected rows in the fits database. Use one of
#'  - a vector of `fitids`
#'  - 'all' for all fits
#'  - a named list to filter fits. List items are `<field in fdb> = <value>`, 
#'    where `<value>` is a regex for character fields, or an actual value (or vector of 
#'    values) for logical or numeric fields.
#' @param score Set the subjective model score in the fits database. This may be numeric 
#'    or character; it'll be treated as a character.
#' @param assess Sets the assessment comment in the fits database
#' @param map Sets the map comment in the fits database
#' @param multiple If TRUE, allows applying to multiple fits
#' @export


fitset <- function(rows, score = NULL, assess = NULL, map = NULL, multiple = FALSE) {
   
   
   load_database('fdb')                         # Get fit database
   
   if(dim(the$fdb)[1] == 0) {
      message('No fits in database')
      return(invisible())
   }
   
   sel <- filter_fits(rows)                     # Selected rows
   
   if(length(sel) == 0)
      stop('No fits selected')
   
   if(length(sel) > 1 & !multiple)
      stop('Multiple rows were selected. If you meant to do this, try again with multiple = TRUE')
   
   
   if(!is.null(score)) 
      the$fdb$score[sel] <- score
   
   if(!is.null(assess))
      the$fdb$comment_assess[sel] <- assess
      
   if(!is.null(map))
      the$fdb$comment_map[sel] <- map
   
   save_database('fdb')
   
   message('Fits database updated for fit', ifelse(length(sel) > 1, 's ', ' '), paste(the$fdb$id[sel], collapse = ', '))
}