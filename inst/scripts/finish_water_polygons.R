# finish_water_polygons - second script to label water classes
# 
# Workflow:
#    1. Create NDWIg
#    2. Create line shapefile with splitting lines
#    3. Run make_water_polygons
#    4. Label polygons
#    5. run this
#
# 2 Apr 2026



library(sf)

x <- st_read('C:/Work/etc/saltmarsh/data/nor_unet/water_polys_split.shp')

# --- Additional 0.3m inward buffer on creeks and pools only ---
is_creek_pool <- x$subclass %in% c(22, 25)
x$geometry[is_creek_pool] <- st_buffer(x[is_creek_pool, ], -0.3) |> st_geometry()
x <- x[!st_is_empty(x), ]                                    # in case any small pools vanish

# --- Outward buffer for background ---
bg <- st_buffer(x, 0.5)                                      # expand outward from original edges
bg <- st_sf(geometry = st_cast(st_union(bg), 'POLYGON'))
bg <- st_difference(bg, st_union(x))                          # subtract the water polys
bg$subclass <- 0L                                             # background class

# --- Combine water + background ---
water_and_bg <- rbind(x, bg)

st_write(water_and_bg, 'C:/Work/etc/saltmarsh/data/nor_unet/water_polys_final.shp', append = FALSE)