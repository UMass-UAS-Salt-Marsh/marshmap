#' Sample orthoimages for field-collected data
#' 
#' Sample images at points where we have field-collected data, creating a data table for modeling.
#' 
#' There are three mutually exclusive sampling strategies (n, p, and d). You
#' must choose exactly one. `n` samples the total number of points provided. 
#' `p` samples the proportion of total points (after balancing, if `balance` is 
#' selected. `d` samples points with a mean (but not guaranteed) minimum distance.
#' 
#' Portable names are used for variable names in the resulting data files. Dashes
#' from modifications are changed to underscore to avoid causing trouble.
#' 
#' Results are saved in four files, plus a metadata file:
#' 
#' 1. `<result>_all.txt` - A text version of the full dataset (selected by `pattern` 
#'    but not subsetted by `n`, `p`, `d`, `balance`, or `drop_corr`). Readable by
#'    any software.
#' 2. `<result>_all.RDS` - An RDS version of the full dataset; far faster to read 
#'    than a text file in R (1.1 s vs. 14.4 s in one example).
#' 3. `<result>.txt` - A text version of the final selected and subsetted dataset,
#'    as a text file.
#' 4. `<result>.RDS` - An RDS version of the final dataset.
#' 5. `<result>_vars.txt` - Lists the portable names used for variables in the sample
#'    alongside the file names on disk. This disambiguates when there are duplicate
#'    portable names in a flights directory.
#' 
#' @param site One or more site names, using 3 letter abbreviation. Use `all` to process all sites. 
#'    In batch mode, each named site will be run in a separate job.
#' @param pattern File names, portable names, regex matching either, or search names
#'    selecting files to sample. See Image naming in
#'    [README](https://github.com/UMass-UAS-Salt-Marsh/salt-marsh-mapping/blob/main/README.md) 
#'    for details. The default is `{*}`, which will include all variables.
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
#' @param balance If TRUE, balance number of samples for each class. Points will be randomly
#'    selected to match the sparsest class.
#' @param balance_excl Vector of classes to exclude when determining sample size when 
#'    balancing. Include classes with low samples we don't care much about. Overrides 
#'    `balance_exclude` from `sites.txt` if supplied.
#' @param drop_corr Drop one of any pair of variables with correlation more than `drop_corr`.
#' @param reuse Reuse the named file (ending in `_all.txt`) from previous run, rather
#'    than resampling. Saves a whole lot of time if you're changing `n`, `p`, `d`, `balance`, 
#'    `balance_excl`, or `drop_corr`.
#' @param result Name of result file. If not specified, file will be constructed from
#'    site, number of X vars, and strategy.
#' @param transects Name of transects file; default is `transects`.
#' @param resources Slurm launch resources. See \link[slurmcollie]{launch}. These take priority
#'    over the function's defaults.
#' @param local If TRUE, run locally; otherwise, spawn a batch run on Unity
#' @param trap If TRUE, trap errors in local mode; if FALSE, use normal R error handling. Use this
#'    for debugging. If you get unrecovered errors, the job won't be added to the jobs database. Has
#'    no effect if local = FALSE.
#' @param comment Optional slurmcollie comment
#' @importFrom slurmcollie launch get_resources
#' @export


sample <- function(site, pattern = '{*}', n = NULL, p = NULL, d = NULL, 
                   classes = NULL, minscore = 0, maxmissing = 20, balance = TRUE, 
                   balance_excl = NULL, result = NULL, transects = NULL, 
                   drop_corr = NULL, reuse = FALSE, 
                   resources = NULL, local = FALSE, trap = TRUE, comment = NULL) {
   
   
   site <- get_sites(site)
   
   if(all(c(is.null(n), is.null(p), is.null(d))))                          # if n, p, and d are all omitted, default to p = 0.25, a quarter of data
      p <- 0.25
   
   if(sum(!is.null(n), !is.null(p), !is.null(d)) != 1)
      stop('You must choose exactly one of the n, p, and d options')
   
   
   if(is.null(balance_excl)) {                                             # if balance_excl is supplied, use it
      x <- as.numeric(unlist(strsplit(site$balance_exclude, ',')))         #    otherwise, get it from sites.txt
      if(length(x) != 0)
         balance_excl <- x
   }
   
   
   resources <- get_resources(resources, list(
      ncpus = 1,
      memory = 64,                                 # the most I've seen is 61.55 GB
      walltime = '2:00:00'                         # longest run: 28:43
   ))
   
   if(is.null(comment))
      comment <- paste0('sample ', site$site)
   
   launch('do_sample', reps = site$site, repname = 'site', 
          moreargs = list(pattern = pattern, n = n, p = p, d = d, classes = classes, minscore = minscore,
                          maxmissing = maxmissing, balance = balance, balance_excl = balance_excl, 
                          result = result, transects = transects, drop_corr = drop_corr, reuse = reuse), 
          finish = 'sample_finish', local = local, trap = trap, resources = resources, comment = comment)
}
