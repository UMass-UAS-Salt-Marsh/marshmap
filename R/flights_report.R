#' Produce reports on orthoimages for all sites
#' 
#' Produce reports on orthoimages, including site summaries, files flagged for 
#' repair, duplicated portable names, and all files for each site
#'
#' The site report is a series of text files. 
#' 
#'   1. Summary of orthos for each site, with stats and frequency tables
#'      for each site. Unformatted text file, suitable for viewing in a text
#'      editor.
#'   2. List of orthos flagged for repair. Tab-delimited text file with columns 
#'      `site`, `name`, `score`, and `comment`. Best viewed in Excel or read into R.
#'   3. List of duplicated portable names. Tab-delimited text file with columns
#'      `site`, `portable`, `name`, `pick` (`*` for selected images), `dups`, 
#'      `season`, and `score`. Best viewed in Excel or read into R.
#'   4. List of all orthos. Tab-delimited text file with columns `site`, `portable`, 
#'      `name`, `type`, `sensor`, `derive`, `window`, `tide`, `tidemod`, `season`, 
#'      `year`, `score`, and `repair`.  Best viewed in Excel or read into R.
#'    
#' Files are written to the `reports/` directory.
#'
#' @importFrom lubridate stamp now with_tz
#' @importFrom utils capture.output
#' @importFrom graphics hist
#' @export


flights_report <- function() {
   
   
   freq_table <- function(col = NULL, title, classes = NULL, x) {                                      # make a frequency table for a column, sorted to match classes
      if(!is.null(col)) {
         x <- as.data.frame(table(db[, col], useNA = 'ifany'))
         names(x) <- c(col, 'count')
         if(!is.null(classes))
            x <- x[order(match(x[, col], c(classes, '', NA))), ]
      }
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
         db$scoren[is.na(db$scoren)] <- 0
         
         x <- paste0('Site: ', toupper(sites$site[i]), ', ', sites$site_name[i])             # 1. flights summary
         x <- paste(strrep('-', nchar(x)), x, strrep('-', nchar(x)), sep = '\n')
         x <- paste0('\n\n', x, '\n\n', nrow(db), ' images, ', sum(db$scoren != 0), 
                     ' scored (', round(sum((db$scoren != 0) / nrow(db)) * 100, 0), '%)\n')
         b <- sum(db$bands, na.rm = TRUE) + sum(is.na(db$bands))
         if(any(is.na(db$bands)))
            x <- paste0(x, 'At least ', b, ' total bands (some images have not been screened)\n')
         else
            x <- paste0(x, b, ' total bands\n')
         
         x <- paste0(x, freq_table('score', 'Distribution of scores'))
         x <- paste0(x, freq_table('sensor', 'Distribution of sensors', the$category$sensor))
         x <- paste0(x, freq_table('type', 'Distribution of image types', the$category$type))
         x <- paste0(x, freq_table('tide', 'Distribution of tide levels', the$category$tide))
         x <- paste0(x, freq_table('season', 'Distribution of seasons', seasons))
         x <- paste0(x, freq_table('year', 'Distribution of years'))
         
         p <- db$pct_missing[!is.na(db$pct_missing)]
         if(length(p) > 0) {
            h <- hist(p, breaks = seq(0, 100, 10), plot = FALSE)
            h$labels <- paste0(paste(h$breaks[-length(h$breaks)], h$breaks[-1], sep = '-'), '%')
            m <- data.frame(range = h$labels, count = h$counts)
            x <- paste0(x, freq_table(x = m, title = 'Distribution of missing values'))
         }
         
         z_summary <- c(z_summary, x)
         
         
         repair <- db[db$repair == TRUE, ]                                                   # 2. list of files flagged for repair
         if(nrow(repair) >= 1) {
            repair <- repair[, c('site', 'name', 'pct_missing', 'score', 'comment')]
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
         dups <- dups[, c('site', 'portable', 'name', 'pick', 'dups', 
                          'season', 'pct_missing', 'score')]
         row.names(dups) <- NULL                                                             # reset row numbers
         
         if(is.null(z_dups))
            z_dups <- dups
         else
            z_dups <- rbind(z_dups, dups)
      }
      
      all <- db[order(db$sensor, db$type, db$derive, db$window, db$tide, db$tidemod, 
                      db$season, db$year, db$score, db$repair), ]                            # 4. list all orthos
      all <- db[, c('site', 'portable', 'name', 'sensor', 'type', 'derive', 'window', 'tide', 'tidemod',
                    'season', 'year', 'pct_missing', 'score', 'repair')]
      
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