# I think I want to normalize importance by kappa (option normalize = TRUE)
# Summaries by type, sensor, season, and tide (pull these out before summazing so means are correct)
#    be careful about high.spring vs. the season spring
#    pull these from pars.yml and seasons.txt




importance <- function(ids = NULL) {
   
   library(dplyr)
   
   if(is.null(ids)) {
      load_database('fdb')
      ids <- the$fdb$id[the$fdb$status == 'finished']
   }
   
   
   ids <- ids[43:48]  ################ FOR DEBUGGING
   
   z <- list()
   for(i in seq_along(ids)) {                                           # for each fit,
      x <- assess(ids[i], top = 999, quiet = TRUE)$importance           #    get variable importance
      x$portable <- rownames(x)
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