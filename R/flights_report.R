#' Produce a flights report for one or more sites
#'
#' The site report is series of tab-delimited text files:
#' 
#'   1. Summary of orthos for each site
#'   2. List of orthos flagged for repair
#'   3. List of duplicated portable names (* marks selected names)
#    4. List of all orthos
#'    
#' Files are written to the `reports/` directory.
#'
#' @importFrom grDevices pdf
#' @importFrom lubridate stamp now with_tz
#' @export


flights_report <- function() {
   
   
   freq_table <- function(col, title, classes = NULL) {                                         # make a frequency table for a column, sorted to match classes
      x <- as.data.frame(table(db[, col], useNA = 'ifany'))
      names(x) <- c(col, 'count')
      if(!is.null(classes))
         x <- x[order(match(x[, col], c(classes, '', NA))), ]
      x <- paste(capture.output(print(x, row.names = FALSE, right = FALSE)), collapse = '\n')
      z <- paste0('\n\n', title, '\n\n', x, '\n')
   }
   
   
   sites <- get_sites('all')
   z_summary <- z_repair <- z_dups <- z_all <- NULL
   timestamp <- stamp('5 Aug 2025, 3:22 pm', quiet = TRUE)                 
   z_summary <- paste0('Flights summary, ', timestamp(with_tz(now(), 'America/New_York')))
   
   
   seasons <- read_pars_table('seasons')$season
   
   
   
   for(i in seq_len(nrow(sites))) {                                                          # for each site,
      db <- get_flights_db(sites$site[i], noerror = TRUE)                                    #    get the flights database
      
      scores <- c('0 - unscored', '1 - rejected', '2 - poor', '3 - fair', 
                  '4 - good', '5 - very good', '6 - excellent')
      db$scoren <- db$score                                                                  # rename numeric name to scoren; and score to e.g., "6 - excellent"
      db$score <- scores[db$scoren + 1]
      
      if(!is.null(db)) {
         db$site <- sites$site[i]
         
         
         x <- paste0('Site: ', toupper(sites$site[i]), ', ', sites$site_name[i])             # 1. flights summary
         x <- paste(strrep('-', nchar(x)), x, strrep('-', nchar(x)), sep = '\n')
         x <- paste0('\n\n', x, '\n\n', nrow(db), ' images, ', sum(db$scoren != 0), 
                     ' scored (', round(sum((db$scoren != 0) / nrow(db)) * 100, 0), '%)')
         
         x <- paste0(x, freq_table('score', 'Distribution of scores'))
         x <- paste0(x, freq_table('type', 'Distribution of image types', the$category$type))
         x <- paste0(x, freq_table('sensor', 'Distribution of sensors', the$category$sensor))
         x <- paste0(x, freq_table('tide', 'Distribution of tide levels', the$category$tide))
         x <- paste0(x, freq_table('season', 'Distribution of seasons', seasons))
         x <- paste0(x, freq_table('year', 'Distribution of years'))
         
         
         z_summary <- c(z_summary, x)
         
         
         repair <- db[db$repair == TRUE, ]                                                   # 2. list of files flagged for repair
         if(nrow(repair) >= 1) {
            repair <- repair[, c('site', 'name', 'score', 'comment')]
            if(is.null(z_repair))
               z_repair <- repair
            else
               z_repair <- rbind(z_repair, repair)
         }
      }
      
      dups <- db[db$dups > 1, ]                                                              # 3. list duplicated portable names
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
                      db$season, db$year, db$score, db$repair), ]                            # 4. list all orthos
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
   writeLines(z_summary, f)
   
   f <- file.path(the$reportsdir, 'duplicates.txt')
   write.table(z_dups, f, sep = '\t', quote = FALSE, row.names = FALSE, na = '')
   
   f <- file.path(the$reportsdir, 'flagged_for_repair.txt')
   write.table(z_repair, f, sep = '\t', quote = FALSE, row.names = FALSE, na = '')
   
   f <- file.path(the$reportsdir, 'all_orthos.txt')
   write.table(z_all, f, sep = '\t', quote = FALSE, row.names = FALSE, na = '')
   
   
   cat('Reports written to ', the$reportsdir, '\n', sep = '')
}