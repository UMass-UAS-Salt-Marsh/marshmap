#' Filter fits database
#'
#' @param filter Specify fits with one of:
#'  - a vector of `ids`
#'  - 'all' for all fits
#'  - a named list to filter fits. List items are `<field in fits database> = <value>`, 
#'    where `<value>` is a regex for character fields, or an actual value (or vector of 
#'    values) for logical or numeric fields.
#' @param database Name of database, either `fdb` or `mdb`
#' @returns A vector of rows numbers in the selected database
#' @keywords internal


filter_db <- function(filter, database) {
   
   
   if(database == 'mdb')
      id <- 'mapid'
   else
      id <- 'id'
   
   db <- the[[database]]
   
   if(identical(filter, 'all'))                                   # if 'all', return all rows
      return(seq_len(dim(db)[1]))
   
   if(is.numeric(filter)) {                                       # if we have supplied ids,
      z <- match(filter, db[[id]])
      if(any(m <- is.na(z))) {
         message('Note: ids ', paste(filter[m], collapse = ', '), ' don\'t exist')
         z <- z[!m]
      }
      return(z)
   }
   
   if(any(n <- !names(filter) %in% names(db)))                    # else, it's a named list of field = value
      stop('Fields not in fits database: ', paste(names(filter)[n], collapse = ', '))
   z <- rep(TRUE, dim(db)[1])
   for(i in seq_along(filter)) {
      col <- db[, names(filter)[i]]
      val <- filter[[i]]
      if(is.character(col[i]))
         z <- z & ((1:length(col)) %in% grep(val, col))
      else
         z <- z & (col == val)
   }
   
   (seq_len(dim(db)[1]))[z]
}