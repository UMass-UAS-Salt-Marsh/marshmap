#' Display information on maps
#' 
#' Display map specification and run statistics.
#' 
#' @param rows Selected rows in the maps database. Use one of
#'  - a vector of `mapids`
#'  - 'all' for all maps
#'  - a named list to filter maps. List items are `<field in mdb> = <value>`, 
#'    where `<value>` is a regex for character fields, or an actual value (or vector of 
#'    values) for logical or numeric fields.
#' @param cols Selected columns to display. Use one of 
#'   - *brief* (1)
#'   - *normal* (2)
#'   - *long* (3)
#'   - *all* (4)
#'   - 1, 2, 3, or 4 is a shortcut for the above column sets
#'   - A vector of column names to include
#'   
#' @param sort The name of the column to be used to sort the table
#' @param decreasing If TRUE, sort in descending order
#' @param nrows Number of rows to display in the table. Positive numbers
#'   display the first *n* rows, and negative numbers display the last *n* rows.
#'   Use `nrows = NA` to display all rows.
#' @param quiet If TRUE, doesn't print anything, just returns values
#' @paream purged If TRUE, display info for the purged database rather than the live one
#' @param timezone Time zone for launch time; use NULL to leave times in native UTC
#' @returns The model table, invisibly
#' @importFrom lubridate with_tz
#' @export


mapinfo <- function(rows = 'all', cols = 'normal', sort = 'mapid', 
                    decreasing = FALSE, nrows = NA, quiet = FALSE,
                    purged = FALSE, timezone = 'America/New_York') {
   
   
   load_database('mdb', purged = purged)                                               # Get map database
   
   if(dim(the$mdb)[1] == 0) {
      message('No maps in database')
      return(invisible())
   }
   
   
   op <- sapply(c('max.print', 'scipen'), getOption)                                   # set printing options  
   on.exit(options(max.print = op[1], scipen = op[2]))
   options(max.print = 20000, scipen = 5)
   
   
   z <- the$mdb[filter_db(rows, 'mdb'), ]                                              # maps, filtered
   z <- z[order(z[, sort], decreasing = decreasing), ]                                 # and sorted
   
   
   if(!is.na(nrows)) {                                                                 # display just selected rows
      if(nrows > 0)
         z <- z[1:nrows, ]
      else
         z <- z[(dim(z)[1] + nrows + 1):(dim(z)[1]), ] 
   }
   
   if(!is.null(timezone))                                                              # if time zone supplied,
      z$launched <- with_tz(z$launched, timezone)                                      #    format launch time in eastern time zone
   
   
   z$error <- ifelse(is.na(z$error), '', ifelse(z$error, 'error', 'ok'))               # prettier formatting
   z$message <- ifelse(is.na(z$message), '', z$message)
   
   z$cores <- ifelse(is.na(z$cores), '', z$cores)
   z$mem_req <- ifelse(is.na(z$mem_req), '', z$mem_req)
   z$mem_gb <- ifelse(is.na(z$mem_gb), '', formatC(z$mem_gb, format = 'f', digits = 3))
   
   z$map_file <- basename(z$result)
   
   if(is.numeric(cols))                                                                # print only requested columns
      if(cols %in% 1:4)
         cols <- c('brief', 'normal', 'long', 'all')[cols]
   if(cols[1] != 'all') {
      if(cols[1] %in% c('brief', 'normal', 'long', 'all'))
         cols <- switch(cols,
                        brief = c('mapid', 'fitid', 'site', 'mpix', 'success', 'launched', 'status', 'error', 'message'),
                        normal = c('mapid', 'fitid', 'site', 'map_file', 'mpix', 'success', 'launched', 'status', 'error', 'message', 'cores', 'cpu', 'cpu_pct', 'mem_req', 'mem_gb', 'walltime'),
                        long = c('mapid', 'fitid', 'site', 'map_file', 'clip', 'clip_area', 'mpix', 'success', 'launched', 'status', 'error', 'message', 'cores', 'cpu', 'cpu_pct', 'mem_req', 'mem_gb', 'walltime'),
         )
      z <- z[, c(setdiff(c('mapid', 'site'), cols), cols), drop = FALSE]               # always include mapid and site
   }
   
   if(!quiet)
      print(z, row.names = FALSE, na.print = '')                                       # print everything
   return(invisible(z))                                                                # otherwise, silently return map info
}
