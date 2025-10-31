#' Sample Y and X variables for a site
#' 
#' Sample imagery for a site and create rectangular data files for model 
#' fitting. This is an internal function, called by sample.
#' 
#' **Memory requirements: I've measured up to 28.5 GB.**
#' 
#' @param site site, using 3 letter abbreviation
#' @param pattern File names, portable names, regex matching either, or search names
#'    selecting files to sample. See Image naming in
#'    [README](https://github.com/UMass-UAS-Salt-Marsh/marshmap/blob/main/README.md) 
#'    for details.W
#' @param n Number of total samples to return.
#' @param p Proportion of total samples to return. Use p = 1 to sample all.
#' @param d Mean distance in cells between samples. No minimum spacing is guaranteed.
#' @param classes Class or vector of classes in transects to sample. Default is all
#'    classes.
#' @param minscore Minimum score for orthos. Files with a minimum score of less than
#'    this are excluded from results. Default is 0, but rejected orthos are always 
#'    excluded.
#' @param maxmissing Maximum percent missing in orthos. Files with percent missing greater
#'    than this are excluded.
#' @param reclass Vector of paired classes to reclassify, e.g., `reclass = c(13, 2, 3, 4)`
#'    would reclassify all 13s to 2 and 4s to 3, lumping each pair of classes.
#' @param balance If TRUE, balance number of samples for each class. Points will be randomly
#'    selected to match the sparsest class.
#' @param balance_excl Vector of classes to exclude when determining sample size when 
#'    balancing. Include classes with low samples we don't care much about.
#' @param drop_corr Drop one of any pair of variables with correlation more than `drop_corr`.
#' @param reuse Reuse the named file (ending in `_all.txt`) from previous run, rather
#'    than resampling. Saves a whole lot of time if you're changing `n`, `p`, `d`, `balance`, 
#'    `balance_excl`, or `drop_corr`. ** Not implemented yet! **
#' @param result Name of result file. If not specified, file will be constructed from
#'    site, number of X vars, and strategy.
#' @param transects Name of transects file; default is `transects`.
#' @returns Sampled data table (invisibly)
#' @importFrom terra rast global subst
#' @importFrom dplyr group_by slice_sample
#' @importFrom caret findCorrelation
#' @importFrom stats cor
#' @keywords internal


do_sample <- function(site, pattern, n, p, d, classes, minscore, maxmissing, reclass,
                      balance, balance_excl, result, transects, drop_corr, reuse) {
   
   
   message('')
   message('-----')
   message('')
   message('Running sample')
   message('site = ', paste(site, collapse = ', '))
   message('pattern = ', pattern)
   if(!is.null(n))
      message('n = ', n)
   if(!is.null(p))
      message('p = ', p)
   if(!is.null(d))
      message('d = ', d)
   if(!is.null(balance_excl))
      message('Excluding subclasses ', paste(balance_excl, collapse = ', '), ' from balancing')
   
   
   if(is.null(result))
      result <- 'data'
   
   sd <- resolve_dir(the$samplesdir, site)
   
   if(reuse) {
      z <- readRDS(f2 <- file.path(sd, paste0(result, '_all.RDS')))
      message('Reusing dataset ', f2)
   }
   
   else {
      
      f <- resolve_dir(the$fielddir, tolower(site))                                 # get field transects
      if(is.null(transects))
         transects <- 'transects.tif'
      field <- rast(file.path(f, transects))
      
      if(!is.null(classes))
         field <- subst(field, from = classes, to = classes, others = NA)           # select classes in transect
      
      
      fl <- resolve_dir(the$flightsdir, tolower(site))
      x <- find_orthos(site, pattern, minscore, maxmissing)                         # find matching files
      xvars <- x$portable                                                           # we'll use the portable name as the variable name
      xfiles <- x$file                                                              # and here are the files for reading and writing to <result>_vars.txt 
      
      
      message('Sampling ', length(xvars), ' variables')
      
      sel <- !is.na(field)                                                          # cells with field samples
      nrows <- as.numeric(global(sel, fun = 'sum', na.rm = TRUE))                   # total sample size
      z <- data.frame(field[sel])                                                   # result is expected to be ~4 GB for 130 variables
      names(z)[1] <- 'subclass'
      
      for(i in seq_along(xfiles)) {                                                 # for each predictor variable,
         x <- rast(file.path(fl, xfiles[i]))                                        #    get the raster
         names(x) <- paste0(xvars[i], '_', 1:length(names(x)))                      #    variable names with _<band number>
         y <- x[sel]
         if(dim(y)[2] == 1)                                                         #    if the variable has one band, vectorize to avoid making a mess
            y <- as.vector(y)
         z[, names(x)] <- y                                                         #    sample selected values
      }
      
      names(z) <- sub('^(\\d)', 'X\\1', names(z))                                   # add an X to the start of names that begin with a digit
      z <- round(z, 2)                                                              # round to 2 digits, which seems like plenty
      
      
      if(!is.null(reclass)) {                                                       # if reclassifying,
         rcl <- matrix(reclass, length(reclass) / 2, 2, byrow = TRUE)
         for(i in nrow(rcl)) {
            z$subclass[r$subclass == rcl[i, 1]] <- rcl[i, 2]
            message('Subclass ', rcl[i, 1], ' reclassified as ', rcl[i, 2])
         }
      }
      
      
      if(!dir.exists(sd))
         dir.create(sd, recursive = TRUE)
      write.table(z, f <- file.path(sd, paste0(result, '_all.txt')), 
                  sep = '\t', quote = FALSE, row.names = FALSE, na = '')
      saveRDS(z, f2 <- file.path(sd, paste0(result, '_all.RDS')))
      message('Complete dataset saved to ', f, ' and ', f2)
   }
   
   
   if(balance) {                                                                    # if balancing samples,
      counts <- table(z$subclass)
      if(!is.null(balance_excl))
         message('Excluding ', length(balance_excl), ' classes from balancing')
      counts <- counts[!as.numeric(names(counts)) %in% balance_excl]                #    excluding classes in balance_excl
      target_n <- min(counts)
      
      z <- group_by(z, subclass) |>
         slice_sample(n = target_n) |>                                              #    take minimum subclass n for every class
         data.frame()                                                               #    and cure tidyverse infection
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
      message('Applying drop_corr = ', drop_corr, ' reduced X variables from ', length(xvars), ' to ', dim(z)[2] - 1)
   }
   
   
   write.table(z, f <- file.path(sd, paste0(result, '.txt')), 
               sep = '\t', quote = FALSE, row.names = FALSE, na = '')
   saveRDS(z, f2 <- file.path(sd, paste0(result, '.RDS')))
   
   x <- cbind(xvars, xfiles)
   names(x) <- c('var', 'file')
   write.table(x, file.path(sd, paste0(result, '_vars.txt')), 
               sep = '\t', quote = FALSE, row.names = FALSE, na  = '')
   
   message('Sampled dataset saved to ', f, ' and ', f2)
}