#' Display information on model fits
#' 
#' Display model specification, assessment, 
#' and run statistics *or* display a model assessment *or* set model scores or
#' comments.
#' 
#' `fitinfo` works in three different modes:
#'  - `fitinfo(rows = <selected rows>, cols = <selected columns>)` displays a table 
#'     of selected rows and columns
#'  - `fitinfo(rows = <a single row>, cols = 'report')` displays a report for the 
#'    selected fit id, focusing on the model assessment (the same information in 
#'    the `fit` log)
#'  - Any of
#'    ```
#'    fitinfo(rows = <a single row>, score = <fit score>)
#'    fitinfo(rows = <a single row>, assess = 'an assessment comment')
#'    fitinfo(rows = <a single row>, map = 'a map comment')
#'    ```
#'    sets the subjective model fit score, the assessment comment, or the map
#'    comment. Any of these may be combined in a single call.
#'    
#' @param rows Selected rows in the fits database. Use one of
#'  - a vector of `fitids`
#'  - 'all' for all fits
#'  - a named list to filter fits. List items are `<field in fdb> = <value>`, 
#'    where `<value>` is a regex for character fields, or an actual value (or vector of 
#'    values) for logical or numeric fields.
#' @param cols Selected columns to display. Use one of 
#'   - *brief* (1)
#'   - *normal* (2)
#'   - *long* (3)
#'   - *all* (4)
#'   - *report*
#'   - 1, 2, 3, or 4 is a shortcut for the above column sets
#'   - A vector of column names to include
#'   
#' @param report If TRUE, give a report (on a single fit); otherwise, list info on fits. 
#'    If rows is a numeric scalar, report defaults to TRUE; otherwise FALSE
#' @param score Set the subjective model score in the fits database. This may be numeric 
#'    or character; it'll be treated as a character.
#' @param assess Sets the assessment comment in the fits database.
#' @param map Sets the map comment in the fits database.
#' @param sort The name of the column to be used to sort the table
#' @param decreasing If TRUE, sort in descending order
#' @param nrows Number of rows to display in the table. Positive numbers
#'   display the first *n* rows, and negative numbers display the last *n* rows.
#'   Use `nrows = NA` to display all rows.
#' @param quiet If TRUE, doesn't print anything, just returns values
#' @param timezone Time zone for launch time; use NULL to leave times in native UTC
#' @returns The fit table or assessment, invisibly
#' @importFrom lubridate with_tz
#' @export


fitinfo <- function(rows = 'all', cols = 'normal', report = TRUE) {
   
   load_database('fdb')
   
   
   if(dim(the$fdb)[1] == 0) {
      message('No fits in database')
      return(invisible())
   }
   
   
   
   
   
   
   
   # ----------------------- THIS IS ALL from slurmcollie::info. Use it as a starting point ------------------------------
   
   if(summary) {
      x <- data.frame(table(slu$jdb$status))
      x <- data.frame(cbind(status = as.character(x[, 1]), jobs = x[, 2]))
      ordering <- data.frame(status = c('pending', 'queued', 'running', 'finished', 'error', 'killed', 'timeout', 'failed'), order = 1:8)
      y <- x[order(merge(x, ordering, by = 'status')$order), ]
      
      if(any(!slu$jdb$done))
         message(sum(!slu$jdb$done), ' job', ifelse(sum(!slu$jdb$done) != 1, 's', ''), ' not done\n')
      else
         message('All jobs done\n')
      
      print(y, row.names = FALSE)
   }
   
   # Now put together jobs table, whether we print it or not, as it's also returned
   
   z <- slu$jdb[filter_jobs(filter), ]                                                                # jobs database, filtered
   z <- z[order(z[, sort], decreasing = decreasing), ]                                                # and sorted
   
   z$mem_gb <- round(z$mem_gb, 3)
   
   if(!is.na(nrows)) {                                                                                # display just selected rows
      if(nrows > 0)
         z <- z[1:nrows, ]
      else
         z <- z[(dim(z)[1] + nrows + 1):(dim(z)[1]), ] 
   }
   
   
   if(!is.null(timezone))                                                                             # if time zone supplied,
      z$launched <- with_tz(z$launched, timezone)                                                     #    format launch time in eastern time zone
   
   
   z$local <- ifelse(is.na(z$local), '', ifelse(z$local, 'local', 'remote'))                          # prettier formatting for local, error, and done
   z$error <- ifelse(is.na(z$error), '', ifelse(z$error, 'error', 'ok'))  
   z$done <- ifelse(is.na(z$done), '', ifelse(z$done, 'done', '...'))  
   
   
   if(is.numeric(columns))                                                                            # print only requested columns
      if(columns %in% 1:4)
         columns <- c('brief', 'normal', 'long', 'all')[columns]
   if(columns != 'all') {
      co <- switch(columns,
                   brief = c('jobid', 'status', 'error', 'comment'),
                   normal = c('jobid', 'launched', 'call', 'rep', 'local', 'status', 'error', 'cores', 'cpu', 'cpu_pct', 'mem_req', 'mem_gb', 'walltime', 'comment'),
                   long = c('jobid', 'launched', 'call', 'rep', 'local', 'sjobid', 'status', 'state', 'reason', 'error', 'message', 'done', 'cores', 'cpu', 'cpu_pct', 'mem_req', 'mem_gb', 'walltime', 'log', 'comment')
      )
      z <- z[, co]
   }
   
   if(summary & table)
      cat('\n')
   
   if(table)
      print(z, row.names = FALSE, na.print = '')
   
   return(invisible(z))
}
