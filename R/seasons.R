#' Pull season out of salt marsh imagery files
#' 
#' For now, this returns months. Eventually, it will return our defined flight seasons.
#' 
#' Robust to wildly haphazard file and date formats (e.g., 18Jun2025, 18June25); does 
#' a pretty good job of hunting down the date from the filename. Dates must be in `dmy`
#' format, followed by an underscore. For file names with two dates, finds the first.
#' 
#' @param files Vector of imagery file names
#' @returns Vector of seasons corresponding to files
#' @importFrom lubridate ymd
#' @keywords internal

# Example call:
#    seasons(grep('.tif', list.files('/work/pi_cschweik_umass_edu/marsh_mapping/data/oth/gis/flights'), value = TRUE))



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
   
   dates <- ymd(paste(y, m, d, sep = '-'), quiet = TRUE)
   
   m                                                                                   # for now, just return month *****************
}
