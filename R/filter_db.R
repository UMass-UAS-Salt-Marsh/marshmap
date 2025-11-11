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
         z <- z[!m]
         if(length(m) > 10)                                       # if the list is long
            m <- c(m[1:3], '...', m[length(m) - 2:0])             #    elide the middle
         message('Note: ids ', paste(filter[m], collapse = ', '), ' don\'t exist')
      }
      return(z)
   }
   
   
   if(!is.list(filter))                                           # if it's not a list at this point, it's a vector of site names
      filter <- list(site = paste(filter, collapse = '|'))        #    pass list(site = 'this|that') on
   
   
   if(any(n <- !names(filter) %in% names(db)))                    # else, it's a named list of field = value
      stop('Fields not in fits database: ', paste(names(filter)[n], collapse = ', '))
   
   if(any(is.character(col)))
      col <- as.character(col)
   
   z <- rep(TRUE, dim(db)[1])
   
   
   for(i in seq_along(filter)) {
      col <- db[, names(filter)[i]]
      val <- filter[[i]]
      
      if(is.character(col[1]))
         z <- z & ((1:length(col)) %in% sapply(val, function(x) grep(x, col)))
      else
         z <- z & (col %in% val)  }
   
   (seq_len(dim(db)[1]))[z]
}