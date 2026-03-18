# make_water_polygons - script to delineate polygons of water from high tide NDWI
# 18 Mar 2026



library(sf)
library(terra)


r <- rast('C:/Work/etc/saltmarsh/data/nor_unet/11Aug23_NOR_High_Mica_Ortho__NDWIg.tif')

r <- r > -0.5                                               # NDWI < -0.5 is a good cutoff
r[r == 0] <- NA                                             # water is all we want
x <- st_as_sf(as.polygons(r))                               # fast dissolve (default)
names(x)[1] <- 'water'
x <- suppressWarnings(st_cast(x, 'POLYGON'))                # explode multipolygon to individual polys
x <- x[as.numeric(st_area(x)) >= 1, ]                       # drop < 1 m^2 - only the smallest pools and a ton of noise

x <- st_buffer(x, -0.5)                                     # shrink water to remove sloppy edges
x <- st_sf(geometry = st_cast(st_union(x), 'POLYGON'))      # dissolve again

x$subclass <- 0L                                            # set subclass for editing

st_write(x, 'C:/Work/etc/saltmarsh/data/nor_unet/water_polys.shp', append = FALSE)
