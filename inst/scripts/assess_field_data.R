# Assess field data
# Temporary code for looking at field data shapefiles
# 28 Jul 2025



library(sf)

site <- 'peg'
dir <- 'C:/Work/etc/saltmarsh/data/field'
f <- '_Site_Polgon_Layer.shp'
x <- st_read(file.path(dir, paste0(site, f)))

if(is.character(x$subclass))
   cat('subclass is character\n')
cat('subclass\n')
table(x$subclass, useNA = 'ifany')

cat('SampFormat\n')
table(x$SampFormat, useNA = 'ifany')

plot(x['subclass'])
