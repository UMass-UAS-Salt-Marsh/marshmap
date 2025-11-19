#' Sample Y and X variables for a site
#' 
#' Sample imagery for a site and create rectangular data files for model 
#' fitting. This is an internal function, called by sample.
#' 
#' **Memory requirements: I've measured up to 28.5 GB.**
#' 
#' @param site site, using 3 letter abbreviation
#' @param vars File names, portable names, regex matching either, or search names
#'    selecting files to sample. See Image naming in
#'    [README](https://github.com/UMass-UAS-Salt-Marsh/marshmap/blob/main/README.md) 
#'    for details.W
#' @param n Number of total samples to return (up to number available).
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


do_sample <- function(site, vars, n, p, d, classes, minscore, maxmissing, reclass,
                      balance, balance_excl, result, transects, drop_corr, reuse) {
   
   
   message('')
   message('-----')
   message('')
   message('Running sample')
   message('site = ', paste(site, collapse = ', '))
   message('vars = ', vars)
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
      
      f <- resolve_dir(the$fielddir, tolower(site))                                 # ---- get field transects
      if(is.null(transects))
         transects <- 'transects.tif'
      ft <- file.path(f, transects)                                                 # field transects raster name
      field <- rast(ft)                                                             # read raster of row ids for ground truth shapefile
      
      
      if(!is.null(classes))
         field <- subst(field, from = classes, to = classes, others = NA)           # select classes in transect
      
      
      fl <- resolve_dir(the$flightsdir, tolower(site))
      x <- find_orthos(site, vars, minscore, maxmissing)                            # find matching files
      xvars <- x$portable                                                           # we'll use the portable name as the variable name
      xfiles <- file.path(fl, x$file)                                               # and here are the files for reading and writing to <result>_vars.txt 
      
      message('Sampling ', length(xvars), ' variables...')
      
      
      bl <- resolve_dir(the$blocksdir, tolower(site))                               # ---- look for blocks files
      blocks <- list.files(bl, pattern = '.tif')
      if(length(blocks) > 0) {                                                      # if there are any blocks files
         xvars <- c(paste0('_', tolower(file_path_sans_ext(blocks))), xvars)        #    block var names start with underscore
         xfiles <- c(file.path(bl, blocks), xfiles)
         message('and sampling ', length(blocks), ' block files...')
      }
      
      
      sel <- !is.na(field)                                                          # ---- cells with field samples
      nrows <- as.numeric(global(sel, fun = 'sum', na.rm = TRUE))                   # total sample size
      z <- data.frame(field[sel])                                                   # result is expected to be ~4 GB for 130 variables
      names(z)[1] <- 'poly'
      
      tf <- paste0(file_path_sans_ext(get_sites(site)$transects), '_final.shp')     # ---- transects shapefile name
      ts <- file.path(resolve_dir(the$shapefilesdir, site), tf)                     # full path to transects shapefile
      shp <- data.frame(st_read(ts, quiet = TRUE))                                  # read transects shapefile
      
      tomerge <- c('poly', 'subclass', 'year', grep('^bypoly\\d+$', names(shp), value = TRUE))
      rows <- nrow(z)
      
      shp$year <- as.numeric(shp$year) ############################ TMEP!!!!!!!!!!!!!!!!!
      
      z <- merge(z, shp[, tomerge])
      if(nrow(z) != rows)
         stop('Shapefile ', ts, ' (', format(nrow(z), big.mark = ','),' values) does not correspond with raster ', ft, ' (', format(rows, big.mark = ','), ' values)')
      
      morecols <- setdiff(names(z), 'subclass')
      z <- z[, c('subclass', morecols)]
      names(z)[2:ncol(z)] <- paste0('_', morecols)
        
      for(i in seq_along(xfiles)) {                                                 # ---- for each predictor variable,
         x <- rast(file.path(xfiles[i]))                                            #    get the raster
         
         if(nlyr(x) == 1)                                                           #    if one layer,
            names(x) <- xvars[i]                                                    #       just use name
         else                                                                       #    else, multiple bands in layer,
            names(x) <- paste0(xvars[i], '_', 1:length(names(x)))                   #       so add _<band number> to variable names
         
         y <- x[sel]
         if(nlyr(x) == 1)                                                           #    if the variable has one band, vectorize to avoid making a mess
            y <- as.vector(y)
         z[, names(x)] <- y                                                         #    sample selected values
      }
      

      names(z) <- sub('^(\\d)', 'X\\1', names(z))                                   # add an X to the start of names that begin with a digit
      z <- round(z, 2)                                                              # round to 2 digits, which seems like plenty
      
      
      if(!is.null(reclass)) {                                                       # if reclassifying,
         rcl <- matrix(reclass, length(reclass) / 2, 2, byrow = TRUE)
         for(i in nrow(rcl)) {
            z$subclass[z$subclass == rcl[i, 1]] <- rcl[i, 2]
            message('Subclass ', rcl[i, 1], ' reclassified as ', rcl[i, 2])
         }
      }
      
      
      if(!dir.exists(sd))
         dir.create(sd, recursive = TRUE)
      write.table(z, f <- file.path(sd, paste0(result, '_all.txt')), 
                  sep = '\t', quote = FALSE, row.names = FALSE, na = '')
      saveRDS(z, f2 <- file.path(sd, paste0(result, '_all.RDS')))
      message('Complete dataset saved to ', f, ' and ', f2, ' (n = ', format(nrow(z), big.mark = ','), ')')
   }
   
   
   if(balance) {                                                                    # if balancing samples,
      counts <- table(z$subclass)
      if(!is.null(balance_excl))
         message('Excluding ', length(balance_excl), ' classes from balancing')
      else
         message('Balance exclusion is off. Minimum class sample size is ', min(counts), '.')
      message('Cases by class')
      print(counts)
      message('')
      
      counts <- counts[!as.numeric(names(counts)) %in% balance_excl]                #    excluding classes in balance_excl
      target_n <- min(counts)
      message('Balancing to ', format(min(counts), big.mark = ','), ' per class')
      
      z <- group_by(z, subclass) |>
         slice_sample(n = target_n) |>                                              #    take minimum subclass n for every class
         data.frame()                                                               #    and cure tidyverse infection
      
      names(z) <- sub('^X_', '_', names(z))                                         #    undo tidyverse shitting on my column names
      
      message('Balancing has reduced dataset from ', format(sum(counts), big.mark = ','), ' cases to ', format(nrow(z), big.mark = ','), ' cases')
      message('')
   }
   
   if(!is.null(d))                                                                  #    if sampling by mean distance,
      p <- 1 / (d + 1) ^ 2                                                          #       set proportion
   
   if(!is.null(p))                                                                  #    if sampling by proportion,
      n <- p * dim(z)[1]                                                            #       set n to proportion
   
   
   z <- z[base::sample(nrow(z), size = min(n, nrow(z)), replace = FALSE), ]         #    sample up to n points
   

   if(!is.null(drop_corr)) {                                                        #----drop_corr option: rdrop correlated variables
      no <- c(match('subclass', names(z)),  grep('^_', names(z)))                   #       non-orthophotos
      before <- ncol(z) - length(no)
      y <- z[, -no]                                                                 #       only look at orthos, of course
      cat('Correlations before applying drop_corr:\n')
      corr <- cor(y, use = 'pairwise.complete.obs')
      print(summary(corr[upper.tri(corr)]))
      c <- sort(findCorrelation(corr, cutoff = drop_corr))
      z <- z[, c(no, c + length(no))]                                              #       drop highly correlated varaibles
      y <- y[, c]
      cat('Correlations after applying drop_corr:\n')
      corr <- cor(y, use = 'pairwise.complete.obs')
      print(summary(corr[upper.tri(corr)]))
      message('Applying drop_corr = ', drop_corr, ' reduced predictor variables from ', before, ' to ', ncol(z) - length(no))
   }
   
   
   write.table(z, f <- file.path(sd, paste0(result, '.txt')), 
               sep = '\t', quote = FALSE, row.names = FALSE, na = '')
   saveRDS(z, f2 <- file.path(sd, paste0(result, '.RDS')))
   
   x <- cbind(xvars, xfiles)
   names(x) <- c('var', 'file')
   write.table(x, file.path(sd, paste0(result, '_vars.txt')), 
               sep = '\t', quote = FALSE, row.names = FALSE, na  = '')
   
   message('Sampled dataset saved to ', f, ' and ', f2, ' (n = ', format(nrow(z), big.mark = ','), ')')
}
