# Plot histogram of flight dates
# Source data: list_orthos.R
# 16 Jun 2025


f <- 'c:/Work/etc/saltmarsh/docs/Orthophoto summary.txt'
x <- readLines(f)
x <- grep('.tif$', x, value = TRUE)
x <- grep('bad_', x, invert = TRUE, value = TRUE)
x <- sub('([ ]*[[0-9]+] )([0-9]+[a-zA-Z]+)(.*)', '\\2', x)        # pull out dates of .tifs
x <- paste0(x, '00')
d <- lubridate::dmy(x)
hist(d, breaks = 'weeks', freq = TRUE, main = 'Flight dates', xlab = 'Date')
