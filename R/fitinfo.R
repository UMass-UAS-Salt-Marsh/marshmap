#' Display information on model fits
#' 
#' Display model specification, assessment, and run statistics.
#' 
#' `fitinfo` works in two different modes:
#'  - `fitinfo(rows = <selected rows>, cols = <selected columns>)` displays a table 
#'     of selected rows and columns
#'  - `fitinfo(rows = <a single row>)` *or* `fitinfo(rows = ..., report = TRUE)` displays 
#'    a report for the selected fit id, focusing on the model assessment (the same 
#'    information in the `fit` log)
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
#'   - 1, 2, 3, or 4 is a shortcut for the above column sets
#'   - A vector of column names to include
#'   
#' Note that `model`, `full_model`, and `hyper` are normally omitted from display, as 
#' they tend to be really long and uninformative. If you want to see them, include them
#' explicitly in `cols`, or use `cols = 'all'` and `include_model = TRUE` to include all three of these.
#'
#' @param report If TRUE, give a report (on a single fit); otherwise, list info on fits. 
#'    If rows is a numeric scalar, report defaults to TRUE; otherwise FALSE.
#' @param sort The name of the column to be used to sort the table
#' @param decreasing If TRUE, sort in descending order
#' @param nrows Number of rows to display in the table. Positive numbers
#'   display the first *n* rows, and negative numbers display the last *n* rows.
#'   Use `nrows = NA` to display all rows.
#' @param include_model if TRUE, don't explicitly exclude `model`, `full_model`, and
#'    `hyper` when `cols = 'all'`
#' @param quiet If TRUE, doesn't print anything, just returns values
#' @paream purged If TRUE, display info for the purged database rather than the live one
#' @param timezone Time zone for launch time; use NULL to leave times in native UTC
#' @returns The fit table or assessment, invisibly
#' @importFrom lubridate with_tz
#' @export


fitinfo <- function(rows = 'all', cols = 'normal', report = NULL,
                    sort = 'id', decreasing = FALSE, nrows = NA, 
                    include_model = FALSE, quiet = FALSE, purged = FALSE,
                    timezone = 'America/New_York') {
   
   
   load_database('fdb', purged = purged)                                               # Get fits database
   
   if(dim(the$fdb)[1] == 0) {
      message('No fits in database')
      return(invisible())
   }
   
   
   op <- sapply(c('max.print', 'scipen'), getOption)                                   # set printing options  
   on.exit(options(max.print = op[1], scipen = op[2]))
   options(max.print = 20000, scipen = 5)
   
   
   z <- the$fdb[filter_db(rows, 'fdb'), ]                                              # fits, filtered
   z <- z[order(z[, sort], decreasing = decreasing), ]                                 # and sorted
   
   if(is.null(report))
      report <- nrow(z) == 1
   
   
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
   z$vars <- ifelse(is.na(z$vars), '', z$vars)
   
   z$cases <- ifelse(z$cases == 'NA', '', prettyNum(z$cases, big.mark = ','))
   z$CCR <- ifelse(is.na(z$CCR), '', paste0(formatC(round(z$CCR * 100, 2), format = 'f', digits = 1), '%'))
   z$kappa <- ifelse(is.na(z$kappa), '', formatC(round(z$kappa, 3), format = 'f', digits = 3))
   
   z$cores <- ifelse(is.na(z$cores), '', z$cores)
   z$mem_req <- ifelse(is.na(z$mem_req), '', z$mem_req)
   z$mem_gb <- ifelse(is.na(z$mem_gb), '', formatC(z$mem_gb, format = 'f', digits = 3))
   
   z$score <- ifelse(is.na(z$score), '', z$score)
   
   
   full_z <- z
   if(is.numeric(cols))                                                                # print only requested columns
      if(cols %in% 1:4)
         cols <- c('brief', 'normal', 'long', 'all')[cols]
   if(cols[1] != 'all') {
      if(cols[1] %in% c('brief', 'normal', 'long', 'all'))
         cols <- switch(cols,
                        brief = c('id', 'name', 'site', 'status', 'error', 'message', 'vars', 'cases', 'CCR', 'kappa', 'comment_launch'),
                        normal = c('id', 'name', 'site', 'status', 'error', 'message', 'vars', 'cases', 'CCR', 'kappa', 'cores', 
                                   'cpu', 'cpu_pct', 'mem_req', 'mem_gb', 'walltime', 'comment_launch', 'score', 'comment_assess', 'comment_map'),
                        long = c('id', 'name', 'site', 'status', 'success', 'error', 'message', 'vars', 'cases', 'CCR', 'kappa', 'cores', 
                                 'cpu', 'cpu_pct', 'mem_req', 'mem_gb', 'walltime', 'comment_launch', 'score', 'comment_assess', 'comment_map', 'call'),
         )
      z <- z[, c(setdiff(c('id', 'site'), cols), cols), drop = FALSE]                  # always include id and site
   }
  
   if(!quiet) {
      if(include_model)                                                                # if include_model, include horribly long columns
         y <- z
      else
         y <- z[!names(z) %in% setdiff(c('model', 'full_model', 'hyper'), cols)]       #    otherwise,don't display these columns unless specifically requested

      if(all(y$comment_assess == ''))
         y <- y[, !names(y) %in% 'comment_assess']
      
      if(all(y$comment_map == ''))
         y <- y[, !names(y) %in% 'comment_map']
      
      print(y, row.names = FALSE, na.print = '')                                       # print everything but the super-long stuff, which still gets returned
   }
   
   if(report & !purged) {                                                              # if we're asking for a report,
      x <- assess(z$id[1], site = z$site[1], quiet = quiet)                            #    display assessment for a single model
      return(invisible(x))                                                             #    and silently return assessment
   }
   else {
      return(invisible(z))                                                             # otherwise, silently return fit info
   }
}
