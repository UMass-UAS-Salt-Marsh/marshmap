#' Produce a summary of variable importance across multiple fits
#'
#' @param fitids Vector of fit fitids, or NULL to run for all finished fits
#' @param vars Vector of variables to restrict analysis to. Default = `{*}`, 
#'    all variables. `vars` is processed by `find_orthos`, and may include file names, 
#'    portable names, search names and regular expressions of file and portable names.
#'    For example, you could use `vars = 'summer | low, mid` to look at importances
#'    only for summer season low and mid tides.
#' @param result File name to write results to. If NULL, one will be constructed.
#' @param normalize If TRUE, normalize importance by Kappa, so better fits get more importance 
#' @param min_ccr The minimum CCR to accept (percentage) to keep from polluting
#'    importance with bad fits
#' @importFrom lubridate now
#' @importFrom dplyr summarise group_by
#' @importFrom stringr str_replace
#' @importFrom utils capture.output
#' @export


# result is a text file in reports/ with header info, then for each attribute (sensor, type, derive, tide, season),
# a table of variables and importance stats

# Summaries by type, sensor, season, and tide (pull these out before summazing so means are correct)
#    be careful about high.spring vs. the season spring
#    pull these from pars.yml and seasons.txt


importance <- function(fitids = NULL, vars = NULL, result = NULL, normalize = TRUE, min_ccr = 70) {
   
   
   make_summary <- function(x, file, name, what = NULL) {                        # summarize importances x, filtered for what and print to file
      if(!is.null(what))
         x$portable <- what
      
      y <- group_by(x, portable) |>
         summarise(mean = mean(importance), 
                   min = min(importance), 
                   max = max(importance), 
                   n = length(importance)) |>
         data.frame()
      
      y$mean <- round(y$mean, 3)
      y <- y[order(y$mean, decreasing = TRUE), ]
      names(y)[1] <- name
      
      
      capture.output(print(y, row.names = FALSE), file = file, append = TRUE)
      cat('\n\n', file = file, append = TRUE)
      
      invisible()
   }
   
   
   load_database('fdb')
   if(is.null(fitids))
      fitids <- the$fdb$id[the$fdb$status == 'finished']
   
   frow <- match(fitids, the$fdb$id)
   if(any(is.na(frow))) {
      message('Skipping fitids that are not in database: ', paste(fitids[is.na(frow)], collapse = ', '))
      fitids <- fitids[!is.na(frow)]
      frow <- frow[!is.na(frow)]
   }
   
   if(!is.null(min_ccr)) {                                                       # if min_ccr, drop low-quality fits
      b <- (the$fdb$CCR[frow] * 100) >= min_ccr
      fitids <- fitids[b]
      frow <- frow[b]
   }
   
   z <- list()
   for(i in seq_along(fitids)) {                                                 # for each fit,
      ef <- file.path(the$modelsdir, paste0('fit_', fitids[i], '_extra.RDS'))    #    get complete variable importance
      
      if(!file.exists(ef)) {
         message('Sidecar file ', ef, ' for fit ', fitids[i], ' is missing. Skipping this one.') 
         next
      }
      
      if(normalize & is.na(the$fdb$kappa[frow[i]])) {
         message('Kappa for fit ', fitids[i], ' is nodata. Skipping this one.')
         next
      }
      
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
   
   b <- !sapply(z, is.null)
   z <- z[b]                                                                     # clean up from missing sidecar files
   fitids <- fitids[b]
   
   x <- do.call(rbind, z)                                                        # make them into one big happy data frame
   names(x) <- tolower(names(x))
   x$portable <- sub('_\\d$', '', x$portable)                                    # drop band, since we care about flights
  
   
   gr <- suppressWarnings(do.call(rbind.data.frame, 
                                  c(str_split(paste0(x$portable, '_'), 
                                              '_'))))[, 1:6]                     # -> 6 col data frame, finessing optional 'deriv'
   names(gr) <- c('type', 'sensor', 'season', 'year', 'tide', 'deriv')
   
   
   if(!dir.exists(the$reportsdir))
      dir.create(the$reportsdir, recursive = TRUE)
   if(is.null(result))
      result <- paste0('importance', fitids[1], ifelse(length(fitids) > 1, paste0('-', fitids[length(fitids)]), ''), '.txt')
   f <- file.path(the$reportsdir, result)
   
   
   info <- paste0('Importance summary, ', now('America/New_York'))
   info <- paste0(info, '\n   fitids = ', paste(fitids, collapse = ', '))
   info <- paste0(info, '\n   vars = ', ifelse(is.null(vars), 'all', paste(vars, collapse = ', ')))
   info <- paste0(info, '\n   normalize = ', normalize)
   info <- paste0(info, '\n   min_ccr = ', min_ccr, '\n\n')
   writeLines(info, f)
   
   make_summary(x, f, 'file')                                                    # print summary tables
   make_summary(x, f, 'type', gr$type)
   make_summary(x, f, 'sensor', gr$sensor)
   make_summary(x, f, 'season', gr$season)
   make_summary(x, f, 'tide', gr$tide)
   make_summary(x, f, 'year', gr$year)
   
   message('Results written to ', f)
}