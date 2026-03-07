#' Number polygons spatially for each subclass to give spatially-reasonable holdout sets 
#' 
#' Polygons are numbered from `1:count`, starting at the northwest-most centroid and taking
#' the closest centroid in turn. Numbering is stratified by `field`. Results are placed in
#' field `poly00` in the `sf` object.
#' 
#' @param shape `sf` object
#' @param field Name of field to stratify on; use NULL for no stratification
#' @param count How many groups? You probably want 10.
#' @returns The modified `sf` object
#' @importFrom sf st_centroid
#' @export


spatial_holdout <- function(shape, field = 'subclass', count = 10) {
   
   
   shape$poly00 <- NA
   if(is.null(field))
      targets <- 1
   else
      targets <- sort(unique(shape[[field]]))
   
   ctrs <- suppressWarnings(st_centroid(shape))$geometry
   ctrs <- data.frame(t(apply(as.matrix(ctrs), 1, unlist)))             # x,y of poly centroids
   names(ctrs) <- c('x', 'y')
   ctrs$nw <- ctrs$x - ctrs$y                                           # northwestness - lower values are closer to NW corner
   ctrs$poly <- shape$poly
   done <- rep(FALSE, nrow(shape))                                      # flag for polys that have been visited   
   
   
   for(i in targets) {                                                  # for each subclass,
      b <- shape[[field]] == i                                          #    polys in target subclass
      
      s <- ctrs[b,]
      j <- match(s$poly[order(s$nw)[1]], ctrs$poly)                     #    start in the northwest corner for this subclass
      k <- 0
      
      while(TRUE) {                                                     #    loop over polys
         shape$poly00[j] <- k <- k %% 10 + 1                            #       assign class
         done[j] <- TRUE                                                #       mark it done
         nxt <- ctrs[b & !done, ]                                       #       candidates for next poly
         if(nrow(nxt) == 0)                                             #       if there aren't any, we're done with this subclass
            break
         d <- sqrt((ctrs$x[j] - nxt$x) ^ 2 + (ctrs$y[j] - nxt$y) ^ 2)   #       distance from current poly to candidates
         j <- match(nxt$poly[d == min(d)][1], shape$poly)               #       winner is next
      }
   }
   
   shape
}