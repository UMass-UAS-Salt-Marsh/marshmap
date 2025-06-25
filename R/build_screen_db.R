#' Read and update or build a screening database for a site
#'
#' Reads any existing screen_<site>.txt from flights directory for site, 
#' builds it or updates it for new or deleted files, saves the new version,
#' and returns the path/name and table. Finds classes from `pars.yml` as 
#' case-insensitive underscore-separated words (after applying name fixes).
#'
#' @param site Site abbreviation
#' @param refresh Recreated database from scratch. **Warning:** this will
#'    destroy your existing database, including all assigned scores and 
#'    comments. Requres also supplying `really = TRUE`.
#' @param really If TRUE, allows refresh to recreate the database
#' @returns A list of
#'    \item{db}{Site database table}
#'    \item{db_name}{Path and name of database table}
#' @importFrom lubridate ymd
#' @keywords internal


build_screen_db <- function(site, refresh = FALSE, really = FALSE) {
   
   
   find_targets <- function(targets, names) {                           # find targets as substrings in names
      names <- fix_names(names)                                         #    clean up naming errors
      names <- gsub('-', '_', names)                                    #    treat modifiers are separate names here
      z <- rep(NA, length(names))
      for(j in targets) {
         p <- paste0('^x', j, '_|_', j, '_|_', j, '.tif')
         z[grep(p, names, ignore.case = TRUE)] <- j                     #       find targets as underscore-separated words
      }
      z
   }
   
   
   if(refresh & !really)
      stop('If you use refresh = TRUE, you must also include really = TRUE. This will DESTROY your existing database for this site, including scores and comments.')
   
   site <- tolower(site)
   dir <- resolve_dir(the$flightsdir, site)
   
   if(!dir.exists(dir))                                                 # if there's no flights dir, just return NULL
      return(NULL)
   
   db_name <- file.path(dir, paste0('screen_', site, '.txt'))
   
   
   if(file.exists(db_name) & !refresh)                                  # get or make database
      db <- read.table(db_name, sep = '\t', header = TRUE)
   else
      db <- data.frame(
         name = character(),
         type = character(),
         sensor = character(),
         derive = character(),
         tide = character(),
         tidemod = character(),
         date = ymd(),
         year = integer(),
         season = character(),
         bands = integer(),                                             # bands is calulated when we load images
         score = integer(),                                             # score and comment are entered by user
         comment = character(),
         deleted = logical()
      )
   
   
   x <- list.files(dir)                                                 # list files
   x <- grep('.tif', x, value = TRUE)                                   # only want TIFFs
   
   db$deleted <- !db$name %in% x                                        # flag deleted files
   
   
   y <- x[!x %in% db$name]
   if(length(y) > 0) {                                                  # if any new files are missing from the database,
      i <- nrow(db) + seq_len(length(y))
      db[i, ] <- NA
      
      db$name[i] <- y
      db$type[i] <- find_targets(the$category$type, y)
      db$type[i] <- ifelse(is.na(db$type[i]), 
                           the$category$type[1], db$type[i])            #    special case: omitted type gets 1st type (should be 'ortho')
      deriv <- grep('__', db$name)
      db$type[deriv] <- 'derived'                                       #    derived variables get type = 'derived' no matter what sensor was used
      db$sensor[i] <- find_targets(the$category$sensor, y)
      db$derive[i] <- find_targets(the$category$derive, y)
      db$tide[i] <- find_targets(the$category$tide, y)
      db$tidemod[i] <- find_targets(the$category$tidemod, y)
      s <- seasons(y)
      db$date[i] <- s$date
      db$year[i] <- s$year
      db$season[i] <- s$season
      db$score[i] <- 0                                                  #    score starts with 0 = not scored
      db$comment[i] <- ''
      db$deleted[i] <- FALSE
      
      
      for(j in deriv) {                                                 #    get minimum of parent's scores for derived variables
         p <- strsplit(db$name[j], '__')[[1]]                           #    get component names
         p <- p[-length(p)]                                             #    drop derivation info
         db$score[j] <- min(db$score[match(paste0(p, '.tif'), db$name)])#    get minimum parent's score
      }
   }
   
   
   save_screen_db(db, db_name)

   invisible(list(db = db, db_name = db_name))
}