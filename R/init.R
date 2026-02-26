#' Initialize marshmap with user parameters
#' 
#' Reads user-set parameters for package marshmap.
#' 
#' User parameters are set in two distinct locations:
#' 
#' 1. The initialization file, in the user's home directory, `~/marshmap.yml`. 
#' This file must contain these five lines:
#' 
#'    `basedir: c:/Work/etc/marshmap` \cr
#'    `parsdir: pars` \cr
#'    `parsfile: pars.yml` \cr
#'    `scratchdir: c:/Work/etc/marshmap/data/scratch` \cr
#' 
#'    a. `basedir` points to the base directory
#'    
#'    b. `parsdir` is the parameters subdirectory. It should be `pars` unless you have 
#'        a good reason to change it.
#' 
#'    c. `parsfile` points to the main parameter file. It should be `pars.yml`.
#'    
#'    d. `scratchdir` points to the scratch drive, where the `cache` directory will be located. 
#'        See notes on caching, below.
#'        
#'    It may contain additional lines, for example, to set unetdir as a directory on the project
#'    drive.
#' 
#' 2. Everything else, in `<basedir>/<parsdir>`. The primary parameter file is 
#' `pars.yml`, which points to other parameters (such as `sites.txt`).
#' 
#' These parameters include:
#' 
#' - `sites` the name of the sites file, `sites.txt` by default
#' - `classes` the name of the classes file, `classes.txt` by default
#' - `dirs` alternative names for various subdirectories. The directories will keep
#'    the standard structure--you can change names here but not paths.
#' - `gather` a block of parameters for [gather()]
#' 
#' This approach splits the user- and platform-dependent parameters (`marshmap.yml`)
#' from parameters that are likely to be shared among users and across platforms (those in
#' `parsdir`). It allows multiple users on a shared machine (such as Unity cluster)
#' to set user-specific parameters if need be, while sharing other parameters.
#' 
#' This function reads the user parameters and adds them to the environment `the` with 
#' all parameters. It is automatically run upon loading the package, and may be 
#' rerun by the user if parameter files are changed.
#' 
#' You can change standard directory names (`data`, `models`, `gis`, `flights`, `field`, 
#' `shapefiles`, `samples`, `predicted`, and `cache`) by setting each within a `dirs:` block in `pars.yml`.
#' Directories default to standard names, which is usually what you want.
#' 
#' To change parameters on the fly, you can set the components of `the`. If you change any elements of 
#' `dirs`, you'll have to run [set_dirs()] afterwards. Note
#' that parameters changed on the fly will only persist until the next call to `init()`, 
#' which can be called on demand but also happens automatically when the package is loaded.
#' 
#' For example:
#' 
#' `the$sites <- 'newsites'`  \cr
#' `the$dirs$cache <- 'newcache'` \cr
#' `the$dirs$samples <- 'samples99'` \cr
#' `set_dirs()`
#' 
#' **Notes on caching.** A cache directory is required when `sourcedrive = google` or `sftp`. The cache 
#'   directory should be larger than the total amount of data processed--this code isn't doing any quota 
#'   management. This is not an issue when using a 
#'   \href{https://docs.unity.rc.umass.edu/documentation/managing-files/hpc-workspace/}{scratch drive on Unity},
#'   as the limit is 50 TB. There's no great need to carry over cached data over long periods, as downloading 
#'   from Google or SFTP to Unity is very fast. Be polite and release the scratch workspace when you're done. 
#'   See comments in [get_file()] for more notes on caching.
#' 
#' @export


init <- function() {
   
   
   # Note: 'the' is created as an environment by aaa.R
   
   if(Sys.getenv('GITHUB_ACTIONS') == 'true')                                          # DON'T RUN THIS FROM GITHUB BECAUSE IT BREAKS PKGDOWN!
      return()
   
   f <- file.path(path.expand('~'), 'marshmap.yml')
   if(!file.exists(f))
      stop('User parameter file ', f, ' not found')
   x <- yaml::read_yaml(f)
   for(i in 1:length(x)) 
      the[[names(x)[i]]] <- x[[i]]
   
   
   p <- c('basedir', 'parsdir', 'parsfile', 'scratchdir') 
   if(any(t <- !p %in% names(the)))
      stop('Parameters ', paste0(p[t], collapse = ', ') , ' are missing from ', f)
   
   the$parsdir <- file.path(the$basedir, the$parsdir)                                 # path to parameter files
   
   x <- yaml::read_yaml(file.path(the$parsdir, the$parsfile))
   for(i in 1:length(x)) 
      the[[names(x)[i]]] <- x[[i]]
   
   set_dirs()                                                                         # and create all full paths
   
   packageStartupMessage('marshmap parameters initialized\n')
}