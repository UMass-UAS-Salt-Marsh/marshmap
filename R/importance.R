#' Produce a summary of variable importance across multiple fits
#'
#' 
#' @param fitids Vector of fit fitids, or NULL to run for all finished fits
#' @param constrain A list of attributes to constrain images, e.g., 
#'    `contrain = list(season = 'summer', tide = c('low', 'mid'))`. This would
#'    only include images captured in summer with low or mid-tide.
#' @param normalize If TRUE, normalize importance by Kappa, so better fits get more importance 
#' @export


# result is a text file in reports/ with header info, then for each attribute (sensor, type, derive, tide, season),
# a table of variables and importance stats

# I think I want to normalize importance by kappa (option normalize = TRUE)
# Summaries by type, sensor, season, and tide (pull these out before summazing so means are correct)
#    be careful about high.spring vs. the season spring
#    pull these from pars.yml and seasons.txt


importance <- function(fitids = NULL) {
   
   library(dplyr)
   
   if(is.null(fitids)) {
      load_database('fdb')
      fitids <- the$fdb$id[the$fdb$status == 'finished']
   }
   
   
   fitids <- fitids[43:48]  ################ FOR DEBUGGING
   
   frow <- match(fitids, the$fdb$id)
   
   z <- list()
   for(i in seq_along(fitids)) {                                           # for each fit,
      x <- assess(fitids[i], top_importance = 999, quiet = TRUE)$importance           #    get variable importance      ** might be able to make this much faster by reading directly from extras file
      x$portable <- rownames(x)
      if(normalize)                                                     # If normalize,
         x$importance <- x$importance * the$fdb$kappa[frow[i]]          #    multiply importance by Kappa
      z[[i]] <- x
   }
   
   x <- do.call(rbind, z)                                               # make them into one big happy data frame
   names(x) <- tolower(names(x))
   x$portable <- sub('_\\d$', '', x$portable)                           # drop band, since we care about flights
   
   y <- group_by(x, portable) |>
      summarise(mean = mean(importance), 
                min = min(importance), 
                max = max(importance), 
                n = length(importance)) |>
      data.frame()
   
   y$mean <- round(y$mean, 3)
   
   y <- y[order(y$mean, decreasing = TRUE), ]
}