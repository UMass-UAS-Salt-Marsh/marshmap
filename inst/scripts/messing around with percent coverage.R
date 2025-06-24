# messing around with calculating % coverage of an orthophoto
# abandonded because it's way too slow for the web app
# just look at the damn image



x <- rasterize(xxx$footprint, xxx$full)                     # convert footprint to raster
y <- xxx$full


s1 <- global(!is.na(x) & !is.na(y), fun = 'sum')
s2 <- global(sum(!is.na(x)), fun = 'sum')

y[is.na(x)] <- NA                                           # clip image to poly
y <- crop(xxx$full, x)