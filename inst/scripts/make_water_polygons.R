# make_water_polygons -  initial script to label water classes
# 
# Workflow:
#    1. Create NDWIg
#    2. Create line shapefile with splitting lines
#    3. Run this
#    4. Label polygons
#    5. run finish_water_polygons
# 
# 18 Mar 2026
# 2 Apr 2026: revised to buffer both in and out, and split on supplied lines



library(sf)
library(terra)
library(lwgeom)

#r <- rast('C:/Work/etc/saltmarsh/data/nor_unet/11Aug23_NOR_High_Mica_Ortho__NDWIg.tif')     # NDWI does poorly with shadows and sun, and this image was taken early in the morning of a bright day
#r <- r > -0.5

r <- rast('C:/Work/etc/saltmarsh/data/nor_unet/11Aug23_NOR_High_Mica_Ortho.tif')             # instead, use a threshold on NIR. Works way better.
r <- r[[5]] < 3000

r[r == 0] <- NA
x <- st_as_sf(as.polygons(r))
names(x)[1] <- 'water'
x <- suppressWarnings(st_cast(x, 'POLYGON'))
x <- x[as.numeric(st_area(x)) >= 1, ]                          # minimum mapping unit: 1 m^2

# --- Light inward buffer (0.1 m) before splitting ---
#     We'll buffer in some more for creeks and ponds in the 2nd phase; this is what we'll get for ditches
x <- st_buffer(x, -0.1)
x <- x[!st_is_empty(x), ]                                      # drop any polys consumed by buffer
x <- st_sf(geometry = st_cast(st_union(x), 'POLYGON'))         # dissolve and explode

x <- x[as.numeric(st_area(x)) >= 1, ]                          # enforce 1 m MMU again


# --- Split by hand-drawn lines ---
splits <- st_read('C:/Work/etc/saltmarsh/data/nor_unet/nor_water_splits.shp')
splits <- st_combine(splits)                                   # merge all lines into one geometry

split_polys <- lapply(seq_len(nrow(x)), function(i) {
   poly <- x[i, ]
   if (!st_intersects(poly, splits, sparse = FALSE)[1, 1]) {
      return(poly)
   }
   result <- st_split(st_geometry(poly), splits)
   parts <- st_collection_extract(result, "POLYGON")
   out <- poly[rep(1, length(parts)), ]
   st_geometry(out) <- parts
   out
})
x <- do.call(rbind, split_polys)

x$subclass <- 0L                                               # for labeling in GIS

st_write(x, 'C:/Work/etc/saltmarsh/data/nor_unet/water_polys_split.shp', append = FALSE)

print('Now label the polygons in GIS, then run finish_water_polygons')
