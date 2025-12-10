#' Summarize number of field-sampled polys and pixels by class and year
#' 
#' @param site Three letter site code
#' @importFrom terra rast values
#' @importFrom sf st_read
#' @importFrom tidyverse group_by summarise
#' @export


fieldinfo <- function(site) {
   
   
   f <- resolve_dir(the$fielddir, tolower(site))                                 # read field transects raster
   ft <- file.path(f, 'transects.tif')
   field <- rast(ft) 
   
   tf <- paste0(file_path_sans_ext(get_sites(site)$transects), '_final.shp')     # read transects shapefile
   ts <- file.path(resolve_dir(the$shapefilesdir, site), tf) 
   shp <- data.frame(st_read(ts, quiet = TRUE))
   
   g <- values(field)                                                            # get cell counts by poly
   g <- g[!is.na(g)]
   freqs <- data.frame(table(g))
   names(freqs) <- c('poly', 'cells')
   
   x <- merge(shp, freqs)                                                        # merge shapefile and raster cell count
   x <- x[, c('year', 'poly', 'subclass', 'cells')]
   
   
   y <- x |>                                                                     # make a nice table 
      group_by(year, subclass) |>
      summarise(polys = n(), cells = sum(cells), .groups = 'drop')
   
   d <- floor(log10(c(sum(y$polys), y$polys))) + 1                               # combine cells (polys), padded so they line up
   y$w <- d[1] - d[-1] + 1                                                       # max width is the total, of course
   y$pad <- sapply(y$w, function(x) paste(rep(' ', x), collapse = ''))
   y$info <- paste0(format(y$cells, big.mark = ','), y$pad, '(', y$polys, ')   ')
   
   y <- y[, c('year', 'subclass', 'info')]
   z <- pivot_wider(y, names_from = year, values_from = info, names_sort = TRUE, values_fill = '-   ')
   z <- data.frame(z[order(z$subclass), ])
   names(z) <- sub('X', '', names(z))
   
   
   rtc <- group_by(x, year) |> summarize(cells = sum(cells))                     # row totals
   rtc <- rtc[order(rtc$year), ]
   rtp <- group_by(x, year) |> summarize(polys = n())
   rtp <- rtp[order(rtp$year), ]
   
   w <- d[1] - floor(log10(rtp$polys))
   rpad <- sapply(w, function(x) paste(rep(' ', x), collapse = ''))
   rt <- c('Total', paste0(format(rtc$cells, big.mark = ','), rpad, '(', rtp$polys, ')   '))
   z <- rbind(z, rt)
   
   
   ctc <- group_by(x, subclass) |> summarize(cells = sum(cells))                 # column totals and grand total
   ctc <- ctc[order(ctc$subclass), ]
   ctp <- group_by(x, subclass) |> summarize(polys = n())
   ctp <- ctp[order(ctp$subclass), ]
   
   w <- d[1] - floor(log10(c(ctp$polys, sum(ctp$polys))))
   cpad <- sapply(w, function(x) paste(rep(' ', x), collapse = ''))
   
   Total <- paste0(format(c(ctc$cells, sum(ctc$cells)), big.mark = ','), cpad, '(', c(ctp$polys, sum(ctp$polys)), ')   ')
   z <- cbind(z, Total)

   names(z)[-1] <- paste0(names(z)[-1], '   ')
   
   cat('Number of cells (polys) for ', site, ' by subclass and year\n', sep = '')
   print(z, row.names = FALSE)
}
