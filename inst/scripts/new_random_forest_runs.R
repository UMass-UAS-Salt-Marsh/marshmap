# New random forest runs
# January 2026


upscale_clone('nor', 'nor_1m', 1)
upscale_clone('nor', 'nor_50cm', 1)


vars1 <- c('dem_mica_spring_2023_mid', 'dem_mica_fall_2023_mid', 'ortho_mica_fall_2023_mid', 'ortho_mica_post_2022_mid', 'ortho_swir_summer_2022_mid', 'ortho_swir_fall_2021_low', 'ortho_mica_summer_2023_high')

upscale_more('nor', 'nor_1m', 1, vars = vars1)
upscale_more('nor', 'nor_50cm', 1, vars = vars1)


flights_prep('nor_1m', cache = FALSE)
flights_prep('nor_50cm', cache = FALSE)

sample('nor_1m', p = 1, balance = FALSE) 
sample('nor_50cm', p = 1, balance = FALSE) 



vars2 <- vars1[1:5]

fit('nor_1m', vars = vars, bypoly = 'bypoly01', min_class = 75, comment = 'vars1')
fit('nor_1m', vars = vars, bypoly = 'bypoly02', min_class = 75, comment = 'vars1')
fit('nor_1m', vars = vars, bypoly = 'bypoly03', min_class = 75, comment = 'vars1')
fit('nor_1m', vars = vars, bypoly = 'bypoly04', min_class = 75, comment = 'vars1')
fit('nor_1m', vars = vars, bypoly = 'bypoly05', min_class = 75, comment = 'vars1')



# NEED TO ADD year OPTION TO fit!
# pick several upscaled variables for each or maybe just 1 or 2!
# try this approach again with point-based RF and old kernel upscaling. It may come out about the same and would be easier and cleaner.
# 