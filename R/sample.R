#' Sample Y and X variables for a site
#' 
#' There are three mutually available sampling strategies (n, p, and d). You
#' must choose exactly one. `n` samples the total number of points provided. 
#' `p` samples the proportion of total points (after balancing, if `balance` is 
#' selected. `d` samples points with a mean (but not guaranteed) minimum distance.
#' 
#' Results are saved in four files:
#' 
#' 1. <result>_all.txt - A text version of the full dataset (selected by `pattern` 
#'    but not subsetted by `n`, `p`, `d`, `balance`, or `drop_corr`). Readable by
#'    any software.
#' 2. <result>_all.RDS - An RDS version of the full dataset; far faster to read 
#'    in R (1.1 s vs. 14.4 s in one example).
#' 3. <result>.txt - A text version of the final selected and subsetted dataset,
#'    as a text file.
#' 4. <result>.RDS - An RDS version of the final dataset.
#' 
#' **Memory requirements: I've measured up to 28.5 GB.**
#' 
#' @param site One or more site names, using 3 letter abbreviation. Default = all sites.
#' @param pattern Regex filtering rasters of predictor variables, case-insensitive. 
#'    Default = "" (match all). Note: only files ending in `.tif` are included in any case.
#' @param n Number of total samples to return.
#' @param p Proportion of total samples to return. Use p = 1 to sample all.
#' @param d Mean distance in cells between samples. No minimum spacing is guaranteed.
#' @param classes Class or vector of classes in transects to sample. Default is all
#'    classes.
#' @param balance If TRUE, balance number of samples for each class. Points will be randomly
#'    selected to match the sparsest class.
#' @param balance_excl Vector of classes to exclude when determining sample size when 
#'    balancing. Include classes with low samples we don't care much about.
#' @param drop_corr Drop one of any pair of variables with correlation more than `drop_corr`.
#' @param reuse Reuse the named file (ending in `_all.txt`) from previous run, rather
#'    than resampling. Saves a whole lot of time if you're changing `n`, `p`, `d`, `balance`, 
#'    `balance_excl`, or `drop_corr`.
#' @param result Name of result file. If not specified, file will be constructed from
#'    site, number of X vars, and strategy.
#' @param transects Name of transects file; default is `transects`.
#' @returns Sampled data table (invisibly)
#' @importFrom terra rast global subst
#' @importFrom progressr progressor handlers
#' @importFrom dplyr group_by slice_sample
#' @importFrom caret findCorrelation
#' @importFrom stats cor
#' @export


sample <- function(site, pattern = '', n = NULL, p = NULL, d = NULL, 
                   classes = NULL, balance = TRUE, balance_excl = c(7, 33), result = NULL, 
                   transects = NULL, drop_corr = NULL, reuse = FALSE) {
   
   
   handlers(global = TRUE)
   lf <- file.path(the$modelsdir, paste0('sample_', site, '.log'))                  # set up logging
   
   
   if(sum(!is.null(n), !is.null(p), !is.null(d)) != 1)
      stop('You must choose exactly one of the n, p, and d options')
   
   
   msg('', lf)
   msg('-----', lf)
   msg('', lf)
   msg('Running sample', lf)
   msg(paste0('site = ', paste(site, collapse = ', ')), lf)
   msg(paste0('pattern = ', pattern), lf)
   if(!is.null(n))
      msg(paste0('n = ', n), lf)
   if(!is.null(p))
      msg(paste0('p = ', p), lf)
   if(!is.null(d))
      msg(paste0('d = ', d), lf)
   
   
   allsites <- read_pars_table('sites')                                             # site names from abbreviations to paths
   sites <- allsites[match(tolower(site), tolower(allsites$site)), ]
   
   result <- 'data'   # will tart this up
   sd <- resolve_dir(the$samplesdir, tolower(sites$site))
   
   if(reuse) {
      z <- readRDS(f2 <- file.path(sd, paste0(result, '_all.RDS')))
      msg(paste0('Reusing dataset ', f2), logfile = lf)
   }
   
   else {
      
      f <- resolve_dir(the$fielddir, tolower(sites$site))                           # get field transects
      if(is.null(transects))
         transects <- 'transects.tif'
      field <- rast(file.path(f, transects))
      
      
      if(!is.null(classes))
         field <- subst(field, from = classes, to = classes, others = NA)           # select classes in transect
      
      fl <- resolve_dir(the$flightsdir, tolower(sites$site))
      xvars <- list.files(fl, pattern = '.tif$')
      msg(paste0('Sampling ', length(xvars), ' variables'), lf)
      
      sel <- !is.na(field)                                                          # cells with field samples
      nrows <- as.numeric(global(sel, fun = 'sum', na.rm = TRUE))                   # total sample size
      z <- data.frame(field[sel])                                                   # result is expected to be ~4 GB for 130 variables
      names(z)[1] <- 'subclass'
      
      
      pr <- progressor(along = xvars)
      for(xv in xvars) {                                                            # for each predictor variable,
         pr()
         x <- rast(file.path(fl, xv))                                               #    read it and save in result matrix
         names(x)[grep('Band_', names(x))] <- paste0(xv, '_', 1:length(names(x)))   #    rename Band_1 to <layer>_1 (e.g., OTH_Aug_CHM_CSF2012_Thin25cm_TriNN8cm.tif)
         z[, names(x)] <- x[sel]
      }
      
      names(z) <- sub('^(\\d)', 'X\\1', names(z))                                   # add an X to the start of names that begin with a digit
      
      t <- data.frame(apply(z, MARGIN = 2, FUN = as.vector))                        # fix crazy shit with one-column matrices ending up in data frame. I don't understand what happened.
      names(t) <- names(z)
      z <- t
      
      z <- round(z, 2)                                                              # round to 2 digits, which seems like plenty
      
      
      if(!dir.exists(sd))
         dir.create(sd, recursive = TRUE)
      write.table(z, f <- file.path(sd, paste0(result, '_all.txt')), sep = '\t', quote = FALSE, row.names = FALSE)
      saveRDS(z, f2 <- file.path(sd, paste0(result, '_all.RDS')))
      msg(paste0('Complete dataset saved to ', f, ' and ', f2), logfile = lf)
   }
   
   
   if(balance) {                                                                    # if balancing smaples,
      counts <- table(z$subclass)
      counts <- counts[!as.numeric(names(counts)) %in% balance_excl]                #    excluding classe in balance_ex,l
      target_n <- min(counts)
      
      z <- group_by(z, subclass) |>
         slice_sample(n = target_n) |>                                              #    take minimum subclass n for every class
         data.frame(z)                                                              #    and cure tidyverse infection
   }
   
   if(!is.null(d))                                                                  #    if sampling by mean distance,
      p <- 1 / (d + 1) ^ 2                                                          #       set proportion
   
   if(!is.null(p))                                                                  #    if sampling by proportion,
      n <- p * dim(z)[1]                                                            #       set n to proportion
   
   z <- z[base::sample(dim(z)[1], size = n, replace = FALSE), ]                     #    sample points
   
   
   if(!is.null(drop_corr)) {                                                        #----drop_corr option: drop correlated variables
      cat('Correlations before applying drop_corr:\n')
      corr <- cor(z, use = 'pairwise.complete.obs')
      print(summary(corr[upper.tri(corr)]))
      c <- findCorrelation(corr, cutoff = drop_corr)
      z <- z[, -c]
      cat('Correlations after applying drop_corr:\n')
      corr <- cor(z, use = 'pairwise.complete.obs')
      print(summary(corr[upper.tri(corr)]))
      msg(paste0('Applying drop_corr = ', drop_corr, ' reduced X variables from ', length(xvars), ' to ', dim(z)[2] - 1), lf)
   }
   
   
   write.table(z, f <- file.path(sd, paste0(result, '.txt')), sep = '\t', quote = FALSE, row.names = FALSE)
   saveRDS(z, f2 <- file.path(sd, paste0(result, '.RDS')))
   msg(paste0('Sampled dataset saved to ', f, ' and ', f2), logfile = lf)
   
   invisible(z)
}