#' Produce a summary of variable importance across multiple fits
#'
#' 
#' @param fitids Vector of fit fitids, or NULL to run for all finished fits
#' @param vars Vector of variables to restrict analysis to. Default = `{*}`, 
#'    all variables. `vars` is processed by `find_orthos`, and may include file names, 
#'    portable names, search names and regular expressions of file and portable names.
#'    For example, you could use `vars = 'summer | low, mid` to look at importances
#'    only for summer season low and mid tides.
#' @param normalize If TRUE, normalize importance by Kappa, so better fits get more importance 
#' @importFrom dplyr summarise group_by
#' @importFrom stringr str_replace
#' @export


# result is a text file in reports/ with header info, then for each attribute (sensor, type, derive, tide, season),
# a table of variables and importance stats

# Summaries by type, sensor, season, and tide (pull these out before summazing so means are correct)
#    be careful about high.spring vs. the season spring
#    pull these from pars.yml and seasons.txt


importance <- function(fitids = NULL, vars = NULL, normalize = TRUE) {
   
  
   load_database('fdb')
   if(is.null(fitids))
      fitids <- the$fdb$id[the$fdb$status == 'finished']
   
   frow <- match(fitids, the$fdb$id)
   if(any(is.na(frow)))
      stop('Fitids are not in database: ', paste(fitids[is.na(frow)], collapse = ', '))
   
   
   z <- list()
   for(i in seq_along(fitids)) {                                                 # for each fit,
      ef <- file.path(the$modelsdir, paste0('fit_', fitids[i], '_extra.RDS'))    #    get complete variable importance
      if(!file.exists(ef))
         stop('Sidecar file ', ef, ' for fit ', fitids[i], ' is missing. You could try fitpurge(undo = ', fitid, ')') 
      extra <- readRDS(ef)
      x <- varImp(extra$model_object)$importance
      x$portable <- rownames(x)
      rownames(x) <- NULL
      names(x)[1] <- 'importance'
      
      
      if(!is.null(vars)) {                                                       #    if filtering for variables,
         incl <- list()
         sites <- the$fdb$site[frow[i]]                                          #       sites for this fit
         for(j in seq_along(sites))                                              #       for each site,
            incl[[j]] <- find_orthos(sites[j], vars)$portable                    #          filter vars for each site
         x <- x[str_replace(x$portable, '_\\d*$', '') %in% unlist(incl), ]       #       filter importances
      }
      

      if(normalize)                                                              #    if normalize,
         x$importance <- x$importance * the$fdb$kappa[frow[i]]                   #       multiply importance by Kappa
      z[[i]] <- x
   }
   
   
   browser()
   
   x <- do.call(rbind, z)                                                        # make them into one big happy data frame
   names(x) <- tolower(names(x))
   x$portable <- sub('_\\d$', '', x$portable)                                    # drop band, since we care about flights
   
   y <- group_by(x, portable) |>
      summarise(mean = mean(importance), 
                min = min(importance), 
                max = max(importance), 
                n = length(importance)) |>
      data.frame()
   
   y$mean <- round(y$mean, 3)
   
   y <- y[order(y$mean, decreasing = TRUE), ]
}