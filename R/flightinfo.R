#' Summarize orthos at a single site
#' 
#' For each year, for each type + sensor, for each season, for each tide stage,
#' lists names of orthos (%missing).
#'
#' @param site Three letter site code
#' @param derived If TRUE, include derived variables
#' @export


flightinfo <- function(site, derived = FALSE) {
   
   
   site <- tolower(site)
   db <- get_flights_db(site)                                                       # get the flights database
   db <- db[db$deleted == FALSE, ]                                                  # skip deleted flights
   if(!derived) {
      db$derive[is.na(db$derive)] <- ''
      db$window[is.na(db$window)] <- ''
      db <- db[db$derive == '' & db$window == '', ]                                 # if derived = FALSE, skip derived flights too
   }
   
   seasons <- c('pre', 'spring', 'summer', 'fall', 'post')
   tides <- c('low', 'mid', 'high')
   scores <- c('0 - unscored', '1 - rejected', '2 - poor', '3 - fair', 
               '4 - good', '5 - very good', '6 - excellent')
   
   
   cat('Site ', site, ' has ', nrow(db), ' flights\n', sep = '')
   
   years <- unique(db$year)
   years <- years[order(years)]
   for(i in seq_along(years)) {
      sel <- db$year == years[i]
      
      
      db$typesens <- paste0(db$type[sel], ':', db$sensor)
      ts <- sort(unique(db$typesens[sel]))
      if(is.na(years[i]))
         cat('\n(orthos with missing year)\n')
      else
         cat('\n----\n', years[i], '\n----\n', sep = '')
      
      for(j in seq_along(ts)) {                                                     # for each type + sensor,
         sel2 <- sel & db$typesens == ts[j]
         seas <- unique(db$season[sel2])
         seas <- seas[order(match(seas, seasons))]                                  #    seasons for this type + sensor
         cat(strrep(' ', 3), ts[j], '\n', sep = '')
         
         for(k in seq_along(seas)) {                                                #    for each season,
            sel3 <- sel2 & db$season == seas[k]
            tid <- unique(db$tide[sel3])
            tid <- tid[order(match(tid, tides))]                                    #    tides for this type + sensor and season
            cat(strrep(' ', 6), seas[k], '\n', sep = '')
            
            for(l in seq_along(tid)) {                                              #       for each tide stage,
               sel3 <- sel3 & db$tide == tid[l]
               x <- db[sel3, ]
               x <- x[order(x$pct_missing), ]
               
               if(nrow(x) > 0) {
                  cat(strrep(' ', 9), tid[l], ' tide\n', sep = '')
                  cat(paste(paste0(strrep(' ', 12), x$portable, ' [', x$name, '] (', x$pct_missing, '% missing, score = ', scores[x$score + 1], ')')), sep = '\n')
               }
            }
         }
      }
   }
}