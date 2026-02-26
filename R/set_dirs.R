#' Set complete paths to all directories
#' 
#' Sets all directory names from `pars.yml` or defaults. Note that `basedir`, `parsdir`, 
#' and `scratchdir` are set by [init()]. Other directory names set by `init()`, from 
#' `marshmap.yml` in the user's home directory take precedence.
#' 
#' @keywords internal


set_dirs <- function() {
   
   
   set <- function(result, dir)                                            # helper function to set dir if it's not already set
      if(is.null(eval(parse(text = result))))
         eval(parse(text = paste0(result, ' <- "', dir, '"')))
   
   
   for(i in c('models', 'data', 'flights', 'field', 'blocks', 'shapefiles', 'samples', 'unet', 'maps', 'cache', 'logs', 'databases', 'reports'))          # set directory name defaults
      the$dirs[[i]] <- ifelse(is.null(the$dirs[[i]]), i, the$dirs[[i]])
   
   
   set('the$modelsdir', file.path(the$basedir, the$dirs$model))                                          # models
   set('the$datadir', file.path(the$basedir, the$dirs$data, '<site>'))                                   # data/<site>/
   set('the$flightsdir', file.path(the$datadir, the$dirs$flights))                                       # data/<site>/flights/
   set('the$fielddir', file.path(the$datadir, the$dirs$field))                                           # data/<site>/field/
   set('the$blocksdir', file.path(the$datadir, the$dirs$blocks))                                         # data/<site>/blocks/
   set('the$shapefilesdir', file.path(the$datadir, the$dirs$shapefiles))                                 # data/<site>/shapefiles/
   set('the$mapsdir', file.path(the$datadir, the$dirs$maps))                                             # data/<site>/maps/
   set('the$samplesdir', file.path(the$datadir, the$dirs$samples))                                       # data/<site>/samples/
   
   set('the$unetdir', file.path(the$datadir, the$dirs$unet))                                             # data/<site>/unet/
   
   set('the$dbdir', file.path(the$basedir, the$dirs$databases))                                          # fit and job databases directory
   set('the$reportsdir', file.path(the$basedir, the$dirs$reports))                                       # reports directory
   set('the$cachedir', file.path(the$scratchdir, the$dirs$cache))                                        # scratchdir/cache/
}