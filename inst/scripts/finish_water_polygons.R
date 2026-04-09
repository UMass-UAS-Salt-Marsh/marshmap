# finish_water_polygons - second script to finalize water training polygons
# 
# Inputs: 
#    water_polys_split.shp  - labeled, split, inward-buffered water polygons
#    raw_water_polys.shp    - original unbuffered NIR threshold polygons
#    NOR_footprint.shp      - site boundary
#
# Workflow:
#    1. Additional inward buffer on creeks and pools
#    2. Replace creek polygons with scattered circles
#    3. Generate background circles across non-water marsh
#    4. Assign unique poly IDs across all classes
#    5. Write final training polygon set
#
# Apr 2026


library(sf)


# ---- Parameters ----
circle_radius <- 5                                           # meters, for both creek and background circles
creek_coverage <- 1/3                                        # fraction of creek area to cover with circles
n_bg_circles <- 600                                          # background circles — tune to balance classes
water_buffer_gap <- 0.5                                      # exclusion buffer beyond raw water edge (m)
seed <- 42


# ---- Load data ----
x <- st_read('C:/Work/etc/saltmarsh/data/nor_unet/water_polys_split.shp')
raw <- st_read('C:/Work/etc/saltmarsh/data/nor_unet/raw_water_polys.shp')
boundary <- st_read('C:/Work/etc/saltmarsh/data/nor_unet/NOR_footprint.shp')


# ---- Additional inward buffer on creeks and pools ----
is_creek_pool <- x$subclass %in% c(22, 25)
x$geometry[is_creek_pool] <- st_buffer(x[is_creek_pool, ], -0.3) |> st_geometry()
x <- x[!st_is_empty(x), ]


# ---- Creek circles ----
creeks <- x[x$subclass == 22, ]
non_creeks <- x[x$subclass != 22, ]

set.seed(seed)
creek_area <- sum(as.numeric(st_area(creeks)))
circle_area <- pi * circle_radius^2
n_creek_circles <- round(creek_area * creek_coverage / circle_area)

creek_pts <- st_sample(st_union(creeks), n_creek_circles)
creek_circles <- st_buffer(creek_pts, circle_radius)
creek_circles <- st_intersection(creek_circles, st_union(creeks))
creek_circles <- creek_circles[!st_is_empty(creek_circles), ]
creek_circles <- st_sf(geometry = creek_circles)
creek_circles$subclass <- 22L


# ---- Background circles ----
water_exclusion <- st_buffer(st_union(raw), water_buffer_gap)
bg_available <- st_difference(boundary, water_exclusion)

set.seed(seed + 1)
bg_pts <- st_sample(bg_available, n_bg_circles)
bg_circles <- st_buffer(bg_pts, circle_radius)
bg_circles <- st_intersection(bg_circles, bg_available)
bg_circles <- bg_circles[!st_is_empty(bg_circles), ]
bg_circles <- st_sf(geometry = bg_circles)
bg_circles$subclass <- 99L


# ---- Dissolve overlapping circles and assign poly IDs ----
water_and_bg <- rbind(non_creeks[, 'subclass'], 
                      creek_circles[, 'subclass'], 
                      bg_circles[, 'subclass'])

water_and_bg <- do.call(rbind, lapply(split(water_and_bg, water_and_bg$subclass), function(s) {
   dissolved <- st_union(s)
   out <- st_sf(geometry = st_cast(dissolved, 'POLYGON'))
   out$subclass <- s$subclass[1]
   out
}))

water_and_bg$poly <- seq_len(nrow(water_and_bg))

st_write(water_and_bg, 'C:/Work/etc/saltmarsh/data/nor_unet/water_polys_final.shp', 
         append = FALSE)


# ---- Summary ----
message('\nFinal training polygons:')
for (sc in sort(unique(water_and_bg$subclass))) {
   sub <- water_and_bg[water_and_bg$subclass == sc, ]
   n <- nrow(sub)
   a <- round(sum(as.numeric(st_area(sub))))
   px <- round(a / 0.08^2)                                  # approximate pixel count at 8cm
   message('  subclass ', sc, ': ', n, ' polys, ', a, ' m^2, ~', 
           formatC(px, format = 'd', big.mark = ','), ' pixels')
}