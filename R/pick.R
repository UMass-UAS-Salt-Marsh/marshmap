#' Pick the best image from a portable name
#' 
#' Given a portable name and flights database, pick the image matching the 
#' portable name with the highest score. Ties are broken by picking the earliest 
#' day in the season. In the unlikely event there is more than one high-scoring 
#' flight in the the first one in the database is arbitrarily chosen.
#' 
#' @param portable Portable name to find
#' @param db Flights database
#' @returns Row in the database with the chosen image
#' @keywords internal


pick <- function(portable, db) {
   i <- seq_along(db$portable)[match(db$portable, portable, nomatch = 0) == 1]
   if(length(i) <= 1)
      return(i)
   i <- i[db$score[i] == max(db$score[i])]                                       # pick highest score
   i <- i[db$date[i] == min(db$date[i])]                                         # and earliest date if there are ties
   return(i[1])                                                                  # if there are still ties, pick the first one
}
