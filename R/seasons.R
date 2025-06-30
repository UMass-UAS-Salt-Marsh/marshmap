#' Pull season out of salt marsh imagery files
#' 
#' For now, this returns months. Eventually, it will return our defined flight seasons.
#' 
#' Robust to wildly haphazard file and date formats (e.g., 18Jun2025, 18June25); does 
#' a pretty good job of hunting down the date from the filename. Dates must be in `dmy`
#' format, followed by an underscore. For file names with two dates, finds the first.
#' 
#' File names must include at least a month and year to get a season, so 
#' `xOTH_Aug_CHM_CSF2012_Thin25cm_TriNN8cm.tif` will return an NA for season. Such 
#' errors may be fixed by editing `flights_<site>.txt`.
#' 
#' @param files Vector of imagery file names
#' @returns named list of:
#'    \item{date}{vector of dates in `yyyy-mm-dd` format}
#'    \item{year}{vector of years, 4 digit integers}
#'    \item{season}{vector of seasons}
#' @importFrom lubridate ymd year %within%
#' @keywords internal

# Example call:
#    seasons(grep('.tif', list.files('/work/pi_cschweik_umass_edu/marsh_mapping/data/oth/flights'), value = TRUE))



seasons <- function(files) {
   
   
   from_list <- function(x, n)                                                         # extract nth element from each element of a list
      unlist(lapply(x, function(z) z[[n]]))      
   
   months <- c('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')
   
   
   m <- rep(NA, length(files))                                                         # Get month for each file, despite haphazard formats
   for(i in months)
      m[grep(i, files)] <- i
   
   dy <- strsplit(files, m)                                     
   d <- as.numeric(gsub('[^0-9]', '', from_list(dy, 1)))                               # extract day (may not be there)        
   y <- as.numeric(gsub('[^0-9]', '', from_list(strsplit(from_list(dy, 2), '_'), 1)))  # and year
   y <- ifelse(y < 2000, y + 2000, y)
   
   dates <- ymd(paste(y, m, d, sep = '-'), quiet = TRUE)                               # dates
   nd <- is.na(dates)
   dates[nd] <- ymd(paste(y[nd], m[nd], 15, sep = '-'), quiet = TRUE)                  # recover dates with year and month, set day to 15th
   
   
   seasons <- read_pars_table('seasons')
   
   z <- rep(NA, length(dates))                                                         # get seasons
   for(i in seq_along(dates)) 
      if(!is.na(dates[i]))
         z[i] <- seasons$season[dates[i] %within% interval(paste0(year(dates[i]), '-', seasons$start), 
                                                           paste0(year(dates[i]), '-', seasons$end))]
   
   
   list(date = dates, year = y, season = z)
}
