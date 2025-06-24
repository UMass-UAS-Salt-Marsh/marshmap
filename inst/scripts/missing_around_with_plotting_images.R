


library(terra)
x <- rast('/work/pi_cschweik_umass_edu/marsh_mapping/data/oth/flights/02Aug19_OTH_Low_Mica_Ortho.tif')
plotRGB(x, 3, 2, 1, stretch = 'lin')


# for single-band images like SWIR and DEM:
x <- rast('/work/pi_cschweik_umass_edu/marsh_mapping/data/red/flights/a16Jun22_RR_High_SWIR_Ortho.tif')
plot(x, col = map.pal('bcyr'), legend = FALSE)

x <- rast('/work/pi_cschweik_umass_edu/marsh_mapping/data/red/flights/26May2022_RED_Low_HesaiRGB_DEM.tif')
plot(x, col = map.pal('bcyr'), legend = FALSE)

# the upshot: this works pretty well. Not wicked fast, but usable
# upscaling with aggregate takes forever, so not worth it
# stretch is needed to prevent the color intensity error
# image matches that in ArcGIS well enough


### cropping for a zoomed inset
sf = 0.05                                                # size factor
range <- (ext(x)[c(2, 4)] - ext(x)[c(1, 3)])
center <- ext(x)[c(1, 3)] + range * 0.5
ce <- c((center - range * sf), (center + range * sf))[c(1, 3, 2, 4)]
y <- crop(x, ce)

plotRGB(y, 3, 2, 1, stretch = 'lin')




######## junk from here down

swir <- rast('/work/pi_cschweik_umass_edu/marsh_mapping/data/oth/flights/08Sep22_OTH_High_SWIR_Ortho.tif')

scr <- rast('/scratch/workspace/bcompton_umass_edu-cache/cache/26May22_RR_Low_Mica_Ortho.tif')

print(nlyr(x))

plotRGB(x, 1, 2, 3, stretch = 'hist')



y <- stretch(x, minq = 0.25, maxq = 0.75)
plotRGB(y, 1, 2, 3)



# attempt at resample, fails
r <- rast(nrows = 100, ncols = 100)
y1 <- resample(r, x[[1]], method = 'bilinear')
y2 <- resample(r, x[[2]], method = 'bilinear')
y3 <- resample(r, x[[3]], method = 'bilinear')
y <- c(y1, y2, y3)
nlyr(y)
plotRGB(y, 1, 2, 3, stretch = 'hist')


# aggregate to upscale
x2 <- x
#x2[x2 == 65535] <- NA
y <- aggregate(x, fact = 10, fun = mean, na.rm = TRUE)
plotRGB(y, stretch = 'hist')
y2 <- stretch(y, minq = 0.25, maxq = 0.75)

y2 <- stretch(y, smin = 0, smax = 10000); plotRGB(y2)
