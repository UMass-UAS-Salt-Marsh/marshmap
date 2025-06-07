


library(terra)
x <- rast('/work/pi_cschweik_umass_edu/marsh_mapping/data/oth/gis/flights/02Aug19_OTH_Low_Mica_Ortho.tif')

writeRaster(x, '/work/pi_cschweik_umass_edu/marsh_mapping/data/oth/gis/flights/02Aug19_OTH_Low_Mica_Ortho_test.tif', datatype = 'INT2U', 
                        NAflag = 65535, overwrite = TRUE)
x <- rast('/work/pi_cschweik_umass_edu/marsh_mapping/data/oth/gis/flights/02Aug19_OTH_Low_Mica_Ortho_test.tif')


x <- subst(x, from = 65535, to = NA)


swir <- rast('/work/pi_cschweik_umass_edu/marsh_mapping/data/oth/gis/flights/08Sep22_OTH_High_SWIR_Ortho.tif')

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
x2[x2 == 65535] <- NA
y <- aggregate(x, fact = 10, fun = mean, na.rm = TRUE)
plotRGB(y, stretch = 'hist')
y2 <- stretch(y, minq = 0.25, maxq = 0.75)

y2 <- stretch(y, smin = 0, smax = 10000); plotRGB(y2)
