#' Read field data for one site in any of the supported field styles
#'
#' Reads field data (ground truth) from a local file (already fetched from the source drive) and
#' returns polygons for the site, ready for [do_gather] to process. The result has no Z values,
#' lowercase field names (with anything that's not a letter, digit, or underscore turned into
#' underscores), numeric `subclass`, and numeric `year`. It's left in the source projection;
#' `do_gather` reprojects if need be.
#'
#' Field styles:
#'
#' - `old_transects` One shapefile per site of already-buffered polygons (deprecated). `path` is
#'   the site's shapefile. Missing years are filled from `targetyear` if present, and any left
#'   missing are set to 0.
#' - `transects` One GeoPackage for all sites, with raw field geometry in three layers
#'   (`shapes_points`, `shapes_lines`, `shapes_polygons`). Points and lines are buffered here;
#'   see [buffer_field_shapes]. Polygons (photo-interpreted water features) are used as
#'   drawn.
#' - `plots` One GeoPackage for all sites with a plot for each sample (2026 on). Points are
#'   buffered by `buffer` to give circular plots; polygons (e.g., `circles.gpkg` from
#'   `marshfield::get_plots`) are used as is. Year is taken from `date`.
#'
#' @param path Path to local field data file
#' @param style Field style, one of `old_transects`, `transects`, or `plots`
#' @param site Site abbreviation, matched case-insensitively to the `site` field for the
#'   all-sites styles
#' @param buffer Buffer radius (m) for points and lines. Typically 1 m for `transects` and 0.7 m
#'   for `plots`.
#' @returns `sf` object of field polygons for the site
#' @importFrom sf st_read st_zm st_buffer st_make_valid st_geometry st_geometry<- st_geometry_type
#' @keywords internal


read_field <- function(path, style, site, buffer) {


   z <- switch(style,
               old_transects = {
                  z <- st_read(path, promote_to_multi = FALSE, quiet = TRUE)
                  z <- clean_field_names(st_zm(z, drop = TRUE))
                  z$year <- as.numeric(z$year)
                  if(!is.null(z$targetyear))
                     z$year <- ifelse(is.na(z$year), z$targetyear, z$year)              # where year is missing, use targetyear - this will fill in for PI
                  z$year[is.na(z$year)] <- 0                                            # set NA years to 0
                  z
               },
               transects = buffer_field_shapes(path, site, buffer, polygons = TRUE),
               plots = {
                  z <- st_read(path, promote_to_multi = FALSE, quiet = TRUE)
                  z <- clean_field_names(st_zm(z, drop = TRUE))
                  z <- z[!is.na(z$site) & toupper(z$site) == toupper(site), ]
                  pts <- st_geometry_type(z) %in% c('POINT', 'MULTIPOINT')
                  if(any(pts))                                                          # buffer points to circular plots
                     st_geometry(z)[pts] <- st_buffer(st_geometry(z)[pts], buffer)
                  z$year <- as.numeric(substr(as.character(z$date), 1, 4))              # year from date
                  z
               },
               stop('field_style must be one of old_transects, transects, or plots')
   )

   if(is.character(z$subclass))                                                         # if subclass is character, turn it into damn numbers!
      z$subclass <- as.numeric(z$subclass)

   z
}



#' Buffer raw field shapes from the all-sites transects GeoPackage
#'
#' Reads the three layers of raw field geometry for one site and buffers them:
#'
#'  - points are buffered by `buffer`, giving circles of radius `buffer`;
#'  - lines are shortened by `buffer` at each end and then buffered by `buffer`, giving
#'    transects `2 * buffer` wide with rounded ends that reach the ends of the original line.
#'    Lines too short to shorten collapse to their midpoint, giving a circle;
#'  - polygons are used as drawn (if `polygons = TRUE`).
#'
#' Shared by [read_field] (via `gather`) and [fieldinfo].
#'
#' @param file GeoPackage with layers `shapes_points`, `shapes_lines`, and `shapes_polygons`
#' @param site Site abbreviation, matched case-insensitively to the `site` field
#' @param buffer Buffer radius (m) for points and lines, and distance lines are shortened at
#'   each end
#' @param polygons If TRUE, include polygons; if FALSE, drop them
#' @returns `sf` object of buffered field shapes for the site, with cleaned field names
#' @importFrom sf st_read st_zm st_buffer st_make_valid st_geometry st_geometry<- st_sfc st_crs
#' @keywords internal


buffer_field_shapes <- function(file, site, buffer, polygons = TRUE) {


   get <- function(layer) {                                                             # read one layer, keeping just this site
      z <- st_read(file, layer = layer, promote_to_multi = FALSE, quiet = TRUE)
      z <- clean_field_names(st_zm(z, drop = TRUE))                                     #    we don't want Z values!
      z[!is.na(z$site) & toupper(z$site) == toupper(site), ]
   }


   pts <- get('shapes_points')                                                          # points: buffer to circles
   st_geometry(pts) <- st_buffer(st_geometry(pts), buffer)

   lns <- get('shapes_lines')                                                           # lines: shorten at both ends and then buffer,
   g <- st_geometry(lns)                                                                #    giving transects with rounded ends
   if(length(g) > 0)                                                                    #    reaching the ends of the original line
      g <- st_sfc(lapply(g, shorten_line, d = buffer), crs = st_crs(g))
   st_geometry(lns) <- st_buffer(g, buffer)

   z <- rbind(pts, lns)
   if(polygons)                                                                         # polygons: use as drawn, once repaired
      z <- rbind(z, st_make_valid(get('shapes_polygons')))

   z
}



#' Clean field names: lowercase, with runs of other characters turned into underscores
#'
#' Leaves the geometry column alone.
#'
#' @param z `sf` object
#' @returns `z` with cleaned names
#' @keywords internal


clean_field_names <- function(z) {


   n <- names(z)
   k <- n != attr(z, 'sf_column')
   n[k] <- gsub('[^a-z0-9_]+', '_', tolower(n[k]))
   names(z) <- n
   z
}



#' Make field names safe for shapefiles
#' 
#' Shapefiles allow at most 10 characters in field names. If any are longer, `st_write`
#' abbreviates *all* names, mangling ones we rely on (`subclass` becomes `subclss`). Instead, we
#' truncate only the long ones, keeping them unique.
#' 
#' @param z `sf` object
#' @returns `z` with field names of 10 characters or fewer
#' @keywords internal


shapefile_names <- function(z) {
   
   
   n <- names(z)
   k <- n != attr(z, 'sf_column') & nchar(n) > 10
   n[k] <- substr(n[k], 1, 10)
   for(j in which(k)) {                                                                 # keep them unique, still within 10 characters
      m <- 1
      while(sum(n == n[j]) > 1) {
         n[j] <- paste0(substr(n[j], 1, 10 - nchar(m)), m)
         m <- m + 1
      }
   }
   names(z) <- n
   z
}
