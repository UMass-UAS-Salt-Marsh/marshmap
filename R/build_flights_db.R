#' Build or update the flights database
#' 
#' Build or update the flights database for a site, normally called by 
#' `screen`; call if you're unable or unwilling to run `screen`.
#'
#' Reads any existing flights_<site>.txt from flights directory for site, 
#' builds it or updates it for new or deleted files, saves the new version,
#' and returns the path/name and table. Finds classes from `pars.yml` as 
#' case-insensitive underscore-separated words (after applying name fixes).
#' 
#' Files with changed timestamps are presumed to have been re-downloaded
#' with gather (as stamps are set in processing). Files shouldn't be 
#' re-downloaded and replaced unless they've changed on the source, so 
#' these files have presumable been repaired. They are refreshed in the 
#' flights database, ready for re-screening. 
#'
#' @param site Site abbreviation
#' @param refresh Recreated database from scratch. **Warning:** this will
#'    destroy your existing database, including all assigned scores and 
#'    comments. Requires also supplying `really = TRUE`.
#' @param really If TRUE, allows refresh to recreate the database
#' @returns A list of
#'    \item{db}{Site database table}
#'    \item{db_name}{Path and name of database table}
#' @importFrom lubridate ymd ymd_hms
#' @keywords internal


build_flights_db <- function(site, refresh = FALSE, really = FALSE) {
   
   
   find_targets <- function(targets, names) {                           # find targets as substrings in names
      names <- fix_names(names)                                         #    clean up naming errors
      names <- gsub('.', '_', names, fixed = TRUE)                      #    treat modifiers are separate names here
      z <- rep(NA, length(names))
      
      for(j in targets) {
         if(j == 'window'){                                             #       matching window is a special case
            matches <- grep('_w[0-9]*', names)
            z[matches] <- gsub('.*(w[0-9]*).*', '\\1', names[matches])
         }
         else
         {
            p <- paste0('^x', j, '_|_', j, '_|_', j, '.tif')
            z[grep(p, names, ignore.case = TRUE)] <- j                  #       find targets as underscore-separated words
         }
      }
      z
   }
   
   
   if(refresh & !really)
      stop('If you use refresh = TRUE, you must also include really = TRUE. This will DESTROY your existing database for this site, including scores and comments.')
   
   site <- tolower(site)
   dir <- resolve_dir(the$flightsdir, site)
   
   if(!dir.exists(dir))                                                 # if there's no flights dir, just return NULL
      return(NULL)
   
   db_name <- file.path(dir, paste0('flights_', site, '.txt'))
   
   
   if(file.exists(db_name) & !refresh)                                  # get or make database
      db <- read.table(db_name, sep = '\t', quote = '', header = TRUE)
   else
      db <- data.frame(
         name = character(),
         portable = character(),
         dups = integer(),
         type = character(),
         sensor = character(),
         derive = character(),
         window = character(),
         tide = character(),
         tidemod = character(),
         date = ymd(),
         year = integer(),
         season = character(),
         bands = integer(),                                             # bands is calulated when we load images
         score = integer(),                                             # score, repair flag, and comment are entered by user
         repair = logical(),
         comment = character(),
         deleted = logical(),
         filestamp = ymd_hms(),                                         # filestamps are used to check for changed files
         pct_missing = double(),                                        # pct_missing is calculated by flights_prep
         missing_filestamp = ymd_hms()                                  # filestamp for percent missing
      )
   
   
   db$score[is.na(db$score)] <- 0                                       # NAs here wreak havoc
   
   x <- list.files(dir)                                                 # list files
   x <- grep('.tif', x, value = TRUE)                                   # only want TIFFs
   
   db$deleted <- !db$name %in% x                                        # flag deleted files
   
   
   # check timestamps
   i <- match(x, db$name)                                               # indices of files already in database
   d <- round(file.mtime(file.path(dir, x[!is.na(i)])))                 # filestamps for these
   i <- i[!is.na(i)]
   c <- db$filestamp[i] != d
   if(any(c))
      db <- db[-i[db$filestamp[i] != d], ]                              # drop files with changed stamps from database                             
   
   
   y <- x[!x %in% db$name]
   if(length(y) > 0) {                                                  # if any new files are missing from the database,
      i <- nrow(db) + seq_len(length(y))
      db[i, ] <- NA
      
      db$name[i] <- y
      db$type[i] <- find_targets(the$category$type, y)
      db$type[i] <- ifelse(db$type[i] %in% c('', NA), 
                           the$category$type[1], db$type[i])            #    special case: omitted type gets 1st type (should be 'ortho')
      deriv <- grep('__', db$name)
      db$type[deriv] <- 'derived'                                       #    derived variables get type = 'derived' no matter what sensor was used
      db$sensor[i] <- find_targets(the$category$sensor, y)
      db$derive[i] <- find_targets(the$category$derive, y)
      db$window[i] <- find_targets('window', y)                         #    window is hard-wired in find_targets
      
      db$type[i] <- ifelse(db$derive[i] %in% 'delta', 'chm', db$type[i])
      db$sensor[i] <- ifelse(db$type[i] %in% 'chm', 
                             ifelse(db$derive[i] %in% 'delta', 'delta', 'lidar'),
                             db$sensor[i])                              #    annoying special case to set sensor for canopy height models
      
      db$tide[i] <- find_targets(the$category$tide, y)
      the$category$tidemod <- substring(the$category$tide[grep('^\\.', the$category$tide)], 2)
      db$tidemod[i] <- find_targets(the$category$tidemod, y)
      s <- seasons(y)
      db$date[i] <- as.character(ymd(s$date))
      db$year[i] <- s$year
      db$season[i] <- s$season
      db$score[i] <- 0                                                  #    score starts with 0 = not scored
      db$repair[i] <- FALSE
      db$comment[i] <- ''
      db$deleted[i] <- FALSE
      db$filestamp[i] <- as.character(ymd_hms(round(file.mtime(file.path(dir, db$name[i])))))
      db$pct_missing[i] <- NA                                           #    pct_missing is resolved by flights_prep
      db$missing_filestamp[i] <- NA                                     #    this is resolved by flights_prep too
      
      
      # Create portable names
      t <- ifelse(!db$tidemod[i] %in% c('', NA), paste0(db$tide[i], '.', db$tidemod[i]), db$tide[i])
      d <- ifelse(!db$window[i] %in% c('', NA), paste0(db$derive[i], '.', db$window[i]), db$derive[i])
      
      p <- paste(db$type[i], db$sensor[i], db$season[i], db$year[i], t, sep = '_')
      p <- ifelse(!db$derive[i] %in% c('', NA), paste0(p, '_', d), p)
      
      c <- paste0(db$type[i], '_', db$sensor[i])
      c <- ifelse(db$year[i] %in% c('', NA), c, paste0(c, '_', db$year[i]))
      p <- ifelse(db$type[i] %in% 'chm', c, p)
      db$portable[i] <- p
      
      
      for(j in deriv) {                                                 #    get minimum of parent's scores for derived variables
         p <- strsplit(db$name[j], '__')[[1]]                           #    get component names
         p <- p[-length(p)]                                             #    drop derivation info
         db$score[j] <- min(db$score[match(paste0(p, '.tif'), db$name)])#    get minimum parent's score
      }
   }
   
   
   a <- aggreg(rep(1, nrow(db)), db$portable, FUN = sum, drop_by = FALSE)
   db$dups <- a[match(db$portable, a$Group.1),]$x
   

   save_flights_db(db, db_name)
   
   invisible(list(db = db, db_name = db_name))
}
