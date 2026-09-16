#' Summarize number of field-sampled polys and pixels by class and year
#'
#' Produces a table for `site` with subclass in the rows and year in the columns, and the number of
#' 8 cm cells and the number of separate polys (in parentheses) in each cell, with row and column
#' totals. There are two sources of field data, selected by `onefile`.
#'
#' With `onefile = TRUE`, field data for all sites come from a single GeoPackage (`file`) holding
#' raw field geometry in three layers. As these data haven't been buffered, we do it here:
#'
#'  - points are buffered by `buffer`, giving 2 m circles;
#'  - lines are shortened by `buffer` at each end and then buffered by `buffer`, giving 2 m wide
#'    transects with rounded ends that reach the ends of the original line. Lines too short to
#'    shorten collapse to their midpoint, giving a 2 m circle;
#'  - polygons are used as drawn.
#'
#' Cell counts are then areas divided by the area of an 8 cm cell, so they're close but not exact:
#' cells aren't actually laid on a grid, and overlapping polys are counted for each poly they fall
#' in. Note that years are taken as given, unlike the `onefile = FALSE` case, which falls back on
#' `targetyear` and uses year 0 for polys with no year at all.
#'
#' With `onefile = FALSE`, data come from the site's rasterized field transects (`transects.tif`)
#' and the site's transects shapefile, both built by `gather`, and cells are counted exactly.
#'
#' @param site Three letter site code
#' @param onefile If TRUE, read raw field data for all sites from the GeoPackage `file`; if FALSE,
#'    use the site's `transects.tif` and transects shapefile
#' @param file GeoPackage with raw field data for all sites, used when `onefile = TRUE`
#' @param buffer Buffer radius in m for points and lines, and the distance lines are shortened at
#'    each end, used when `onefile = TRUE`
#' @importFrom dplyr n group_by summarize
#' @importFrom tidyr pivot_wider
#' @export


fieldinfo <- function(site, onefile = TRUE,
                      file = 'C:/Work/saltmarsh/data/all_EPA_field/shapes_output.gpkg',
                      buffer = 1) {


   if(onefile)                                                                   # get year, poly, subclass, and cells,
      x <- field_from_gpkg(file, site, buffer)                                   #    either from the all-sites GeoPackage
   else
      x <- field_from_raster(site)                                               #    or from the site's rasterized transects


   y <- x |>                                                                     # make a nice table
      group_by(year, subclass) |>
      summarize(polys = n(), cells = sum(cells), .groups = 'drop')

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



#' Field data for a site from the all-sites GeoPackage of raw field geometry
#'
#' Buffers points and lines to 2 m wide and counts 8 cm cells by area. See `fieldinfo`.
#'
#' @param file GeoPackage with points, lines, and polygons for all sites
#' @param site Three letter site code
#' @param buffer Buffer radius in m, and the distance lines are shortened at each end
#' @returns Data frame with columns `year`, `poly`, `subclass`, and `cells`
#' @importFrom sf st_read st_zm st_area st_buffer st_geometry st_geometry<- st_make_valid st_sfc st_crs
#' @keywords internal


field_from_gpkg <- function(file, site, buffer) {


   cellsize <- 0.08                                                              # we're counting 8 cm cells

   get <- function(layer) {                                                      # read one layer, keeping just this site
      z <- st_read(file, layer = layer, promote_to_multi = FALSE, quiet = TRUE)
      z <- st_zm(z, drop = TRUE)                                                 #    we don't want Z values!
      names(z) <- tolower(names(z))
      z[!is.na(z$site) & toupper(z$site) == toupper(site), c('year', 'subclass')]
   }


   pts <- get('shapes_points')                                                   # points: buffer to 2 m circles
   st_geometry(pts) <- st_buffer(st_geometry(pts), buffer)

   lns <- get('shapes_lines')                                                    # lines: shorten at both ends and then buffer,
   g <- st_geometry(lns)                                                         #    giving 2 m wide transects with rounded ends
   if(length(g) > 0)                                                             #    reaching the ends of the original line
      g <- st_sfc(lapply(g, shorten_line, d = buffer), crs = st_crs(g))
   st_geometry(lns) <- st_buffer(g, buffer)

   pol <- st_make_valid(get('shapes_polygons'))                                  # polygons: use as drawn, once repaired


   x <- rbind(pts, lns, pol)
   if(nrow(x) == 0)
      stop('No field data for site ', site, ' in ', file)

   x$poly <- seq_len(nrow(x))                                                    # unique poly ids
   x$cells <- round(as.numeric(st_area(x)) / cellsize ^ 2)                       # cell counts by area, close enough

   x <- data.frame(x)[x$cells > 0, c('year', 'poly', 'subclass', 'cells')]
   x[order(x$year, x$subclass), ]
}



#' Shorten a linestring by `d` at each end
#'
#' Lines of `2 * d` or shorter collapse to their midpoint, as there's nothing left to shorten.
#'
#' @param g LINESTRING geometry
#' @param d Distance in m to drop from each end
#' @returns Shortened LINESTRING, or a POINT if the line was too short to shorten
#' @importFrom sf st_coordinates st_linestring st_point
#' @keywords internal


shorten_line <- function(g, d) {


   at <- function(s) {                                                           # interpolate the point s along the line
      i <- max(which(cum <= s))
      if(i == length(cum))
         return(p[i, ])
      p[i, ] + (p[i + 1, ] - p[i, ]) * (s - cum[i]) / (cum[i + 1] - cum[i])
   }


   p <- st_coordinates(g)[, 1:2, drop = FALSE]
   cum <- c(0, cumsum(sqrt(diff(p[, 1]) ^ 2 + diff(p[, 2]) ^ 2)))                # distance along the line at each vertex
   len <- cum[length(cum)]

   if(len <= 2 * d)                                                              # too short to shorten, so collapse to midpoint
      return(st_point(at(len / 2)))

   keep <- cum > d & cum < len - d                                               # interior vertices that survive
   st_linestring(rbind(at(d), p[keep, , drop = FALSE], at(len - d)))
}



#' Field data for a site from its rasterized transects
#'
#' This is the original approach, counting actual cells in `transects.tif`. See `fieldinfo`.
#'
#' @param site Three letter site code
#' @returns Data frame with columns `year`, `poly`, `subclass`, and `cells`
#' @importFrom terra rast values
#' @importFrom sf st_read
#' @keywords internal


field_from_raster <- function(site) {


   f <- resolve_dir(the$fielddir, tolower(site))                                 # read field transects raster
   ft <- file.path(f, 'transects.tif')
   field <- rast(ft)

   tf <- paste0(toupper(site), '_transects.shp')                                 # transects shapefile
   ts <- file.path(resolve_dir(the$shapefilesdir, site), tf)
   shp <- data.frame(st_read(ts, quiet = TRUE))

   g <- values(field)                                                            # get cell counts by poly
   g <- g[!is.na(g)]
   freqs <- data.frame(table(g))
   names(freqs) <- c('poly', 'cells')

   x <- merge(shp, freqs)                                                        # merge shapefile and raster cell count
   names(x) <- tolower(names(x))
   x[, c('year', 'poly', 'subclass', 'cells')]
}
