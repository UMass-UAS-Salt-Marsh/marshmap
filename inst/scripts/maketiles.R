# create tiles


library(sf)


rpath <- '/work/pi_cschweik_umass_edu/marsh_mapping/data/peg/blocks/'
result <- 'tiles50.shp'

ground <- st_read(file.path('/work/pi_cschweik_umass_edu/marsh_mapping/data/peg/shapefiles/Peg_Site_Polygon_Layer.shp'))


ground_m <- st_transform(ground, crs = 26986)
tiles_m <- st_make_grid(ground_m, cellsize = 50, what = 'polygons', square = TRUE)
tiles <- st_transform(tiles_m, crs(ground))

plot(tiles)

tiles$block <- seq_len(length(tiles))
st_write(tiles, file.path(rpath, result), append = FALSE)
