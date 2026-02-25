# fix tree shadows in NOR June 2023 ortho
# This is a one-and-done, unless I get a new copy of the ortho
# B. Compton, 24 Feb 2026



library(sf)
library(terra)


# fix unprojected footprint
# x <- st_read('/work/pi_cschweik_umass_edu/marsh_mapping/data/nor/shapefiles/NR_200ac_Mask_24Mar23.shp')
# x <- st_transform(x, crs = 26986)  
# st_write(x, '/work/pi_cschweik_umass_edu/marsh_mapping/data/nor/shapefiles/NOR_footprint.shp')

d
x <- st_read('/work/pi_cschweik_umass_edu/marsh_mapping/data/nor/shapefiles/tree_shadows2.shp')

june <- rast('/work/pi_cschweik_umass_edu/marsh_mapping/data/nor/flights/29Jun23_NOR_Mid_Mica_Ortho.tif')
g <- rasterize(x, june, field = 'field_1')
june[!is.na(g)] <- NA
plot(june[[1]])

writeRaster(june, '/work/pi_cschweik_umass_edu/marsh_mapping/data/nor/flights/29Jun23_NOR_Mid_Mica_Ortho_fixed.tif')

