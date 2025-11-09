#' Create tiles with numbered blocks
#' 
#' Create one or more shapefiles corresponding to the named site with tiles of the
#' specified sizes, numbered in square blocks of 1-9. Used with the `blocks` option
#' in `fit` to reduce the effects of spatial autocorrelation.
#'
#' @param site Site to align tiles with
#' @param sizes Tile size (m); may be a vector to create several sets of tiles
#' @importFrom sf st_read st_transform st_make_grid st_sf st_write
#' @export


maketiles <- function(site, sizes) {
   
   
   source <- file.path(resolve_dir(the$shapefilesdir, site), 
                       basename(get_sites(site)$footprint))
   rpath <- resolve_dir(the$blocksdir, site)
   if(!dir.exists(rpath))
      dir.create(rpath, recursive = TRUE)
   
   
   ground <- st_read(source, quiet = TRUE)                                 # read site footprint
   ground_m <- st_transform(ground, crs = 26986)                           # transform the footprint to Mass State Plane so we're in meters
   
   e <- st_bbox(ground_m)
   ext <- c(e$xmax - e$xmin, e$ymax - e$ymin)                              # extent of footprint in meters
   
   
   for(size in sizes) {                                                    # for each tile size,
      
      tiles_m <- st_make_grid(ground_m, cellsize = size, 
                              what = 'polygons', square = TRUE)            #    make tiles of specified size
      tiles <- st_sf(geometry = st_transform(tiles_m, crs(ground)))        #    transform back to epsg:4326
      
      
      cells <- ceiling(rev(ext) / size)                                    #    rows and columns in cells
      blocks <- ceiling(cells / 3)                                         #    3x3 blocks
      x <- matrix(1:9, 3, 3, byrow = TRUE)                                 #    make a 3x3 block
      y <- do.call(cbind, rep(list(x), blocks[2]))
      z <- do.call(rbind, rep(list(y), blocks[1]))                         #    and repeat it across and down
      z <- z[1:cells[1], 1:cells[2]]                                       #    trim edges
      tiles$block <- as.vector(t(z[cells[1]:1, ]) )                        #    assign blocks to shapefile attribute, top to bottom
      st_write(tiles, f <- file.path(rpath, paste0('tiles', size, '.shp')), 
               append = FALSE, quiet = TRUE)                               #    save the shapefile
      message(f, ' written')
   }
   
   message('Created ', length(sizes), ' tiles shapefile', ifelse(length(sizes == 1), '', 's'), ' for site ', site)
}