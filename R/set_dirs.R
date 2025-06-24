#' Set complete paths to all directories
#' 
#' Sets all directory names from `pars.yml` or defaults. Note that `basedir`, `parsdir`, 
#' and `scratchdir` are set by [init()].
#' 
#' @export


set_dirs <- function() {
   
   
   for(i in c('models', 'data', 'flights', 'field', 'shapefiles', 'samples', 'predicted', 'cache', 'logs', 'databases'))          # set directory name defaults
      the$dirs[[i]] <- ifelse(is.null(the$dirs[[i]]), i, the$dirs[[i]])
   
   the$modelsdir <- file.path(the$basedir, the$dirs$model)                                            # models
   the$datadir <- file.path(the$basedir, the$dirs$data, '<site>')                                     # data/<site>/
   the$flightsdir <- file.path(the$datadir, the$dirs$flights)                                         # data/<site>/flights/
   the$fielddir <- file.path(the$datadir, the$dirs$field)                                             # data/<site>/field/
   the$shapefilesdir <- file.path(the$datadir, the$dirs$shapefiles)                                   # data/<site>/shapefiles/
   the$predicteddir <- file.path(the$datadir, the$dirs$predicted)                                     # data/<site>/predicted/
   the$samplesdir <- file.path(the$datadir, the$dirs$samples)                                         # data/<site>/samples/
   
   the$logdir <- file.path(the$basedir, the$dirs$logs)                                                # job logs directory                          **** am I using this outside of slurmcollie?
   the$dbdir <- file.path(the$basedir, the$dirs$databases)                                            # fit and job databases directory
   the$cachedir <- file.path(the$scratchdir, the$dirs$cache)                                          # scratchdir/cache/
}