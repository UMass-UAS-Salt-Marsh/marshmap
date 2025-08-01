#' Produce a flights report for one or more sites
#'
#' The site report is seroes of tab-delimited text files:
#' 
#'   1. Summary of orthos for each site
#'   2. List of orthos flagged for repair
#'   3. List of duplicated portable names (* marks selected names)
#    4. List of all orthos
#'    
#' Files are written to the `reports/` directory.
#'
#' @importFrom grDevices pdf
#' @importFrom gridExtra grid.table
#' @export


flights_report <- function() {
   
   
   sites <- get_sites('all')
   z_summary <- z_repair <- z_dups <- z_all <- NULL
   for(site in sites) {                                                                   # for each site,
      db <- get_flights_db(site, noerror = TRUE)                                          #    get the flights database
      
      if(!is.null(db)) {
         db$site <- site
         
         x <- paste0('\n\nSite: ', toupper(site), '\n', nrow(db), ' images, ', 
                     sum(db$score != 0), ' scored (', round(sum((db$score != 0) / nrow(db)) * 100, 0), '%)')
         z_summary <- c(z_summary, x)
         
         
         repair <- db[db$repair == TRUE, ]                                                # 2. list of files flagged for repair
         if(nrow(repair) >= 1) {
            repair <- repair[, c('site', 'name', 'score', 'comment')]
            if(is.null(z_repair))
               z_repair <- repair
            else
               z_repair <- rbind(z_repair, repair)
         }
      }
      
      dups <- db[db$dups > 1, ]                                                           # 3. list duplicated portable names
      if(nrow(dups) >= 1) {
         dups$pick <- ''
         dups$pick[sapply(unique(dups$portable), function(x) pick(x, dups))] <- '*'
         dups <- dups[order(dups$portable, dups$pick != '*'), ]
         dups <- dups[, c('site', 'portable', 'name', 'pick', 'dups', 'season', 'score')]
         row.names(dups) <- NULL                                                             # reset row numbers
         
         if(is.null(z_dups))
            z_dups <- dups
         else
            z_dups <- rbind(z_dups, dups)
      }
      
      all <- db[order(db$type, db$sensor, db$derive, db$window, db$tide, db$tidemod, 
                      db$season, db$year, db$score, db$repair), ]                         # 4. list all orthos
      all <- db[, c('site', 'portable', 'name', 'type', 'sensor', 'derive', 'window', 'tide', 'tidemod',
                    'season', 'year', 'score', 'repair')]
      
      if(is.null(z_all))
         z_all <- all
      else
         z_all <- rbind(z_all, all)
   }
   
   
   if(!dir.exists(the$reportsdir))
      dir.create(the$reportsdir, recursive = TRUE)
   
   
   f <- file.path(the$reportsdir, 'summary.txt')
   write.table(z_summary, f, sep = '\t', quote = FALSE, row.names = FALSE, na = '')
   
   f <- file.path(the$reportsdir, 'duplicates.txt')
   write.table(z_dups, f, sep = '\t', quote = FALSE, row.names = FALSE, na = '')
   
   f <- file.path(the$reportsdir, 'flagged_for_repair.txt')
   write.table(z_repair, f, sep = '\t', quote = FALSE, row.names = FALSE, na = '')
   
   f <- file.path(the$reportsdir, 'all_orthos.txt')
   write.table(z_all, f, sep = '\t', quote = FALSE, row.names = FALSE, na = '')
   
   
   cat('Reports written to ', the$reportsdir, '\n', sep = '')
}