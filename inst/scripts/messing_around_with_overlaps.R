# Erase overlaping polys where field `Subclass` is different, but
# keep them where all values are the same
# B. Compton, 21 Aug 2025



library(sf)
library(ggplot2)
library(tidyterra)


x <- st_read('C:/Work/etc/saltmarsh/data/Red River/example2.shp')          # read example data

y <- st_intersection(x)                                                    # intersect shapefile with itself                                     
b <- sapply(y$origins, function(i) length(unique(x$Subclass[i])) == 1)     # TRUE if all overlaps have the same Subclass
z <- y[b, ]                                                                # keep these

ggplot() +
   geom_spatvector(data = z, aes(fill = factor(Subclass)))                 # plot results
