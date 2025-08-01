#' Produce a flights report for one or more sites
#'
#' The site report is a tab-delimited text file listing images flagged for repair.
#'    
#' Files are written to `reports/flagged_for_repair.txt`.
#'    
#' @param site One or more site names, using 3 letter abbreviation. Use `all` to process all sites. 
#' @importFrom grDevices pdf
#' @importFrom gridExtra grid.table
#' @export

# I might add the following at some point if there's need:
#    1. Flights summary page
#    2. List of duplicated portable names (* marks selected names)
#    3. List of all orthos

flights_report <- function(site = 'all') {
   
   
   sites <- get_sites(site)
   z <- NULL
   for(site in sites) {                                                                # for each site,
      db <- get_flights_db(site, noerror = TRUE)                                       #    get the flights database
      if(!is.null(db)) {
         db <- db[db$repair == TRUE, ]
         if(nrow(db) >= 1) {
            if(is.null(z))
               z <- data.frame(site = site, file = db$name, score = db$score, comment = db$comment)
            else
               z <- rbind(z, data.frame(site = site, file = db$name, score = db$score, comment = db$comment))
         }
      }
      
      # dups <- db[db$dups > 1, ]                                                      # list duplicated portable names
      # dups$pick <- ''
      # dups$pick[sapply(unique(dups$portable), function(x) pick(x, dups))] <- '*'
      # dups <- dups[order(dups$portable, dups$pick != '*'), ]
      # dups <- dups[, c('portable', 'name', 'pick', 'dups', 'season', 'score')]
      # row.names(dups) <- NULL                                                          # reset row numbers
   }
   
   if(!dir.exists(the$reportsdir))
      dir.create(the$reportsdir, recursive = TRUE)
   f <- file.path(the$reportsdir, 'flagged_for_repair.txt')
   write.table(z, f, sep = '\t', quote = FALSE, row.names = FALSE, na = '')
   cat(nrow(z), ' files marked for repair written to ', f, '\n', sep = '')
}