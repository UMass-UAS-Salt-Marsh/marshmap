#' Combines multiple maps, filling in missing data
#' 
#' In general, models using more predictors have better performance, but
#' there's a trade-off, as including predictors with missing data will lead
#' to missing areas in resulting maps. Mosaic mitigates for this problem by
#' combining multiple maps. Missing values in the first map are replaced
#' with values from the second map, missing values in the first two maps 
#' are replaced from the third, and so on. The new composite map will have 
#' data for all cells that any of the source maps have data.
#' 
#' A shapefile will be produced with map id, fit id, CCR, and Kappa for 
#' underlying cells.
#' 
#' Maps must all be from the same site.
#' 
#' @param mapids Vector of two or more map ids to process, with preferred maps
#'    listed before less-preferred ones
#' @importFrom terra rast values writeRaster
#' @export


do_mosaic <- function(mapids) {
   
   
   # grab maps database
   # pick a new map id
   # result name is map_<site>_<mapid>_mosaic.tif
   # shapefile is map_<site>_<mapid>_mosaic.shp
   
   
   # z <- rast(path and name of first map)
   index <- z
   values(index) <- NA
   values(index)[!is.na(z)] <- mapids[1]
   
   for(i in 2:seq_len(mapids)) {
   #  x <- rast(path and name of mapids[i])
      values(index)[is.na(z) & !is.na(x)] <- mapids[i]   # update index
      z[is.na(z)] <- x[is.na(z)]                         # replace missing values
   }
   
   # make index into a shapefile
   # add attributes: map id, fit id, CCR, and Kappa
   
   # save raster
   
   
   
   
}