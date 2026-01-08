# New random forest runs
# Data matched by year (within 1 year) + a solid site with strong field data + fewer predictors
# January 2026



upscale_clone('nor', 'nor_1m', 1)
upscale_clone('nor', 'nor_50cm', 1)


vars1 <- c('dem_mica_spring_2023_mid', 'dem_mica_fall_2023_mid', 'ortho_mica_fall_2023_mid', 'ortho_mica_post_2022_mid', 'ortho_swir_summer_2022_mid', 'ortho_swir_fall_2021_low', 'ortho_mica_summer_2023_high')
vars2 <- vars1[1:5]


derive('nor', c('ortho_mica_fall_2023_mid', 'ortho_mica_post_2022_mid'), metrics = 'NDVI')

upscale_more('nor', 'nor_1m', 1, vars = c(vars1, 'ortho_mica_fall_2023_mid__NDVI', 'ortho_mica_post_2022_mid__NDVI'), metrics = 'mean')
upscale_more('nor', 'nor_50cm', 1, vars = c(vars1, 'ortho_mica_fall_2023_mid__NDVI', 'ortho_mica_post_2022_mid__NDVI'), metrics = 'mean')

# upscale_more('nor', 'nor_1m', 1, vars = vars1)
# upscale_more('nor', 'nor_50cm', 1, vars = vars1)





# up to here now ---------------------

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
