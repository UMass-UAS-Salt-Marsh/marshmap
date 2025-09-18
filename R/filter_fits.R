#' Filter fits database
#'
#' @param filter Specify fits with one of:
#'  - a vector of `ids`
#'  - 'all' for all fits
#'  - a named list to filter fits. List items are `<field in fits database> = <value>`, 
#'    where `<value>` is a regex for character fields, or an actual value (or vector of 
#'    values) for logical or numeric fields.
#' @returns A vector of rows numbers in `the$fdb`
#' @keywords internal


filter_fits <- function(filter) {
   
   
   if(identical(filter, 'all'))                                   # if 'all', return all jobs
      return(seq_len(dim(the$fdb)[1]))
   
   if(is.numeric(filter)) {                                       # if we have supplied jobids,
      z <- match(filter, the$fdb$id)
      if(any(m <- is.na(z))) {
         message('Note: fit ids ', paste(filter[m], collapse = ', '), ' don\'t exist')
         z <- z[!m]
      }
      return(z)
   }
   
   if(any(n <- !names(filter) %in% names(the$fdb)))               # else, it's a named list of field = value
      stop('Fields not in fits database: ', paste(names(filter)[n], collapse = ', '))
   z <- rep(TRUE, dim(the$fdb)[1])
   for(i in seq_along(filter)) {
      col <- the$fdb[, names(filter)[i]]
      val <- filter[[i]]
      if(is.character(col[i]))
         z <- z & ((1:length(col)) %in% grep(val, col))
      else
         z <- z & (col == val)
   }
   
   (seq_len(dim(the$fdb)[1]))[z]
}