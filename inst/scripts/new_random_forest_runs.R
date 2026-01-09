# New random forest runs
# Data matched by year (within 1 year) + a solid site with strong field data + fewer predictors
# January 2026



upscale_clone('nor', 'nor_1m', 1)


vars1 <- c('dem_mica_spring_2023_mid', 'dem_mica_fall_2023_mid', 'ortho_mica_fall_2023_mid', 'ortho_mica_post_2022_mid', 'ortho_swir_summer_2022_mid', 'ortho_swir_fall_2021_low', 'ortho_mica_summer_2023_high')
vars2 <- vars1[1:5]


derive('nor', c('ortho_mica_fall_2023_mid', 'ortho_mica_post_2022_mid'), metrics = 'NDVI')
derive('nor', c('ortho_mica_fall_2023_mid', 'ortho_mica_post_2022_mid'), metrics = 'NDRE')   # oops--forgot this one


vars_derived <- c('derived_mica_fall_2023_mid_NDVI', 'derived_mica_post_2022_mid_NDVI', 'derived_mica_fall_2023_mid_NDRE', 'derived_mica_post_2022_mid_NDRE')
upscale_more('nor', 'nor_1m', 1, vars = c(vars1, vars_derived), metrics = c('mean', 'sd', 'r1090', 'iqr'))
upscale_clone('nor', 'nor_50cm', 0.5)

# upscale_more('nor', 'nor_1m', 1, vars = vars1)
# upscale_more('nor', 'nor_50cm', 1, vars = vars1)




upscale_more('nor', 'nor_50cm', 0.5, vars = c(vars1, vars_derived), metrics = c('mean', 'sd', 'r1090', 'iqr'))





flights_prep('nor_1m', cache = FALSE)
flights_prep('nor_50cm', cache = FALSE)

sample('nor_1m', p = 1, balance = FALSE) 
sample('nor_50cm', p = 1, balance = FALSE) 



fit('nor_1m', vars = vars1, bypoly = 'bypoly01', include_years = 2023, min_class = 75, comment = 'vars1')           # try it with means
fit('nor_1m', vars = vars1, bypoly = 'bypoly02', include_years = 2023, min_class = 75, comment = 'vars1')
fit('nor_1m', vars = vars1, bypoly = 'bypoly03', include_years = 2023, min_class = 75, comment = 'vars1')
fit('nor_1m', vars = vars1, bypoly = 'bypoly04', include_years = 2023, min_class = 75, comment = 'vars1')
fit('nor_1m', vars = vars1, bypoly = 'bypoly05', include_years = 2023, min_class = 75, comment = 'vars1')

fit('nor_50cm', vars = vars1, bypoly = 'bypoly01', include_years = 2023, min_class = 75, comment = 'vars1')           # try it with means
fit('nor_50cm', vars = vars1, bypoly = 'bypoly02', include_years = 2023, min_class = 75, comment = 'vars1')
fit('nor_50cm', vars = vars1, bypoly = 'bypoly03', include_years = 2023, min_class = 75, comment = 'vars1')
fit('nor_50cm', vars = vars1, bypoly = 'bypoly04', include_years = 2023, min_class = 75, comment = 'vars1')
fit('nor_50cm', vars = vars1, bypoly = 'bypoly05', include_years = 2023, min_class = 75, comment = 'vars1')


fit('nor_1m', vars = vars2, bypoly = 'bypoly01', include_years = 2023, min_class = 75, comment = 'vars2')           # try it with means
fit('nor_50cm', vars = vars2, bypoly = 'bypoly01', include_years = 2023, min_class = 75, comment = 'vars2')



# pick several upscaled variables for each or maybe just 1 or 2!
# try this approach again with point-based RF and old kernel upscaling. It may come out about the same and would be easier and cleaner.


# up to here now ---------------------


vars3 <- c('dem_mica_spring_2023_mid', 'dem_mica_fall_2023_mid', 
           'derived_mica_fall_2023_mid_NDVI', 'derived_mica_post_2022_mid_NDVI', 'derived_mica_fall_2023_mid_NDRE', 'derived_mica_post_2022_mid_NDRE', 
           'ortho_swir_summer_2022_mid', 'ortho_swir_fall_2021_low', 'ortho_mica_summer_2023_high')
vars4 <- vars3[c(1, 3, 4, 7)]

fit('nor_1m', vars = vars3, bypoly = 'bypoly01', include_years = 2023, min_class = 75, comment = 'vars3')
fit('nor_1m', vars = vars4, bypoly = 'bypoly01', include_years = 2023, min_class = 75, comment = 'vars4')
fit('nor_50cm', vars = vars3, bypoly = 'bypoly01', include_years = 2023, min_class = 75, comment = 'vars3')
fit('nor_50cm', vars = vars4, bypoly = 'bypoly01', include_years = 2023, min_class = 75, comment = 'vars4')


#  ERROR IN CALL
fit('nor_1m', vars = vars4, bypoly = 'bypoly01', include_years = 2023, min_class = 75, comment = 'vars4')
#  [18] Errors in search name: derived_mica_fall_2023_mid_ndvi
#  [19] Errors in search name: derived_mica_post_2022_mid_ndvi
#  
#  NDVI, NDRE are getting dropped in creating portable name, plus I somehow missed NDVI for nor_1m
#  fits I do have are absolutely abysmal, mostly driven by it identifying water
#  fuck this shit.
#  

fit('nor_50cm', vars = vars3, bypoly = 'bypoly01', include_years = 2023, include_classes = 3:6, min_class = 75, max_miss_train = 0.3, comment = 'vars3, classes 3-4-5-6')
fit('nor_50cm', vars = vars4, bypoly = 'bypoly01', include_years = 2023, include_classes = 3:6, min_class = 75, max_miss_train = 0.3, comment = 'vars4, classes 3-4-5-6')
