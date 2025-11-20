# tile fit o'rama

fit('peg', max_samples = 50000, blocks = list(block = 'tiles5', classes = c(1, 5)), comment = 'tiles05 1/5, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles10', classes = c(1, 5)), comment = 'tiles10 1/5, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles20', classes = c(1, 5)), comment = 'tiles20 1/5, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles40', classes = c(1, 5)), comment = 'tiles40 1/5, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles60', classes = c(1, 5)), comment = 'tiles60 1/5, 50k samples')

fit('peg', max_samples = 50000, blocks = list(block = 'tiles5', classes = c(1, 2)), comment = 'tiles05 1/2, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles10', classes = c(1, 2)), comment = 'tiles10 1/2, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles20', classes = c(1, 2)), comment = 'tiles20 1/2, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles40', classes = c(1, 2)), comment = 'tiles40 1/2, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles60', classes = c(1, 2)), comment = 'tiles60 1/2, 50k samples')


fit('oth', max_samples = 50000, blocks = list(block = 'tiles5', classes = c(1, 5)), comment = 'tiles05 1/5, 50k samples')
fit('oth', max_samples = 50000, blocks = list(block = 'tiles10', classes = c(1, 5)), comment = 'tiles10 1/5, 50k samples')
fit('oth', max_samples = 50000, blocks = list(block = 'tiles20', classes = c(1, 5)), comment = 'tiles20 1/5, 50k samples')
fit('oth', max_samples = 50000, blocks = list(block = 'tiles40', classes = c(1, 5)), comment = 'tiles40 1/5, 50k samples')
fit('oth', max_samples = 50000, blocks = list(block = 'tiles60', classes = c(1, 5)), comment = 'tiles60 1/5, 50k samples')

fit('oth', max_samples = 50000, blocks = list(block = 'tiles5', classes = c(1, 2)), comment = 'tiles05 1/2, 50k samples')
fit('oth', max_samples = 50000, blocks = list(block = 'tiles10', classes = c(1, 2)), comment = 'tiles10 1/2, 50k samples')
fit('oth', max_samples = 50000, blocks = list(block = 'tiles20', classes = c(1, 2)), comment = 'tiles20 1/2, 50k samples')
fit('oth', max_samples = 50000, blocks = list(block = 'tiles40', classes = c(1, 2)), comment = 'tiles40 1/2, 50k samples')
fit('oth', max_samples = 50000, blocks = list(block = 'tiles60', classes = c(1, 2)), comment = 'tiles60 1/2, 50k samples')




# --- with derived vars
fit('peg', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles20', classes = c(1, 5)), comment = 'tiles20 1/5, 50k samples, DERIVED')
fit('peg', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles40', classes = c(1, 5)), comment = 'tiles40 1/5, 50k samples, DERIVED')
fit('peg', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles20', classes = c(1, 2)), comment = 'tiles20 1/2, 50k samples, DERIVED')
fit('peg', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles40', classes = c(1, 2)), comment = 'tiles40 1/2, 50k samples, DERIVED')
fit('oth', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles20', classes = c(1, 5)), comment = 'tiles20 1/5, 50k samples, DERIVED')
fit('oth', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles40', classes = c(1, 5)), comment = 'tiles40 1/5, 50k samples, DERIVED')
fit('oth', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles20', classes = c(1, 2)), comment = 'tiles20 1/2, 50k samples, DERIVED')
fit('oth', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles40', classes = c(1, 2)), comment = 'tiles40 1/2, 50k samples, DERIVED')


# --- with ONLY derived vars
fit('peg', vars = 'derived', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles20', classes = c(1, 5)), comment = 'tiles20 1/5, 50k samples, DERIVED only')
fit('peg', vars = 'derived', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles40', classes = c(1, 5)), comment = 'tiles40 1/5, 50k samples, DERIVED only')
fit('peg', vars = 'derived', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles20', classes = c(1, 2)), comment = 'tiles20 1/2, 50k samples, DERIVED only')
fit('peg', vars = 'derived', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles40', classes = c(1, 2)), comment = 'tiles40 1/2, 50k samples, DERIVED only')
fit('oth', vars = 'derived', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles20', classes = c(1, 5)), comment = 'tiles20 1/5, 50k samples, DERIVED only')
fit('oth', vars = 'derived', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles40', classes = c(1, 5)), comment = 'tiles40 1/5, 50k samples, DERIVED only')
fit('oth', vars = 'derived', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles20', classes = c(1, 2)), comment = 'tiles20 1/2, 50k samples, DERIVED only')
fit('oth', vars = 'derived', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles40', classes = c(1, 2)), comment = 'tiles40 1/2, 50k samples, DERIVED only')




# --- play with max.depth           
fit('peg', max_samples = 50000, blocks = list(block = 'tiles40', classes = c(1, 2)), fitargs = list(max.depth = 5), comment = 'tiles40 1/2, 50k samples, max.depth = 5')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles40', classes = c(1, 2)), fitargs = list(max.depth = 10), comment = 'tiles40 1/2, 50k samples, max.depth = 10')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles40', classes = c(1, 2)), fitargs = list(max.depth = 15), comment = 'tiles40 1/2, 50k samples, max.depth = 15')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles40', classes = c(1, 2)), fitargs = list(max.depth = 20), comment = 'tiles40 1/2, 50k samples, max.depth = 20')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles40', classes = c(1, 2)), fitargs = list(max.depth = 30), comment = 'tiles40 1/2, 50k samples, max.depth = 30')


# --- Class level fit
fit('peg', max_samples = 50000, blocks = list(block = 'tiles40', classes = c(1, 2)), reclass = c(1, 10, 2, 10, 3, 10, 4, 10, 5, 10, 6, 10, 7, 10, 8, 10, 9, 10, 11, 10, 12, 10, 21, 20, 22, 20, 23, 20, 25, 20, 31, 30, 32, 30), comment = 'tiles40 1/2, 50k samples, CLASS LEVEL')


# fill out tile fits more (and redo for both, as oth was broken and peg didn't have min_class)

fit('peg', max_samples = 50000, blocks = list(block = 'tiles1', classes = c(1, 2)), comment = 'tiles01 1/2, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles2', classes = c(1, 2)), comment = 'tiles02 1/2, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles5', classes = c(1, 2)), comment = 'tiles05 1/2, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles10', classes = c(1, 2)), comment = 'tiles10 1/2, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles20', classes = c(1, 2)), comment = 'tiles20 1/2, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles40', classes = c(1, 2)), comment = 'tiles40 1/2, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles50', classes = c(1, 2)), comment = 'tiles50 1/2, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles60', classes = c(1, 2)), comment = 'tiles60 1/2, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles100', classes = c(1, 2)), comment = 'tiles100 1/2, 50k samples')

fit('peg', max_samples = 50000, blocks = list(block = 'tiles1', classes = c(1, 5)), comment = 'tiles01 1/5, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles2', classes = c(1, 5)), comment = 'tiles02 1/5, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles5', classes = c(1, 5)), comment = 'tiles05 1/5, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles10', classes = c(1, 5)), comment = 'tiles10 1/5, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles20', classes = c(1, 5)), comment = 'tiles20 1/5, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles40', classes = c(1, 5)), comment = 'tiles40 1/5, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles50', classes = c(1, 5)), comment = 'tiles50 1/5, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles60', classes = c(1, 5)), comment = 'tiles60 1/5, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles100', classes = c(1, 5)), comment = 'tiles100 1/5, 50k samples')

fit('peg', max_samples = 50000, blocks = list(block = 'tiles1', classes = c(2, 6)), comment = 'tiles01 2/6, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles2', classes = c(2, 6)), comment = 'tiles02 2/6, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles5', classes = c(2, 6)), comment = 'tiles05 2/6, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles10', classes = c(2, 6)), comment = 'tiles10 2/6, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles20', classes = c(2, 6)), comment = 'tiles20 2/6, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles40', classes = c(2, 6)), comment = 'tiles40 2/6, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles50', classes = c(2, 6)), comment = 'tiles50 2/6, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles60', classes = c(2, 6)), comment = 'tiles60 2/6, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles100', classes = c(2, 6)), comment = 'tiles100 2/6, 50k samples')

fit('peg', max_samples = 50000, blocks = list(block = 'tiles1', classes = c(4, 8)), comment = 'tiles01 4/8, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles2', classes = c(4, 8)), comment = 'tiles02 4/8, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles5', classes = c(4, 8)), comment = 'tiles05 4/8, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles10', classes = c(4, 8)), comment = 'tiles10 4/8, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles20', classes = c(4, 8)), comment = 'tiles20 4/8, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles40', classes = c(4, 8)), comment = 'tiles40 4/8, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles50', classes = c(4, 8)), comment = 'tiles50 4/8, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles60', classes = c(4, 8)), comment = 'tiles60 4/8, 50k samples')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles100', classes = c(4, 8)), comment = 'tiles100 4/8, 50k samples')


fit('oth', max_samples = 50000, blocks = list(block = 'tiles5', classes = c(1, 5)), comment = 'tiles05 1/5, 50k samples')
fit('oth', max_samples = 50000, blocks = list(block = 'tiles10', classes = c(1, 5)), comment = 'tiles10 1/5, 50k samples')
fit('oth', max_samples = 50000, blocks = list(block = 'tiles20', classes = c(1, 5)), comment = 'tiles20 1/5, 50k samples')
fit('oth', max_samples = 50000, blocks = list(block = 'tiles40', classes = c(1, 5)), comment = 'tiles40 1/5, 50k samples')
fit('oth', max_samples = 50000, blocks = list(block = 'tiles60', classes = c(1, 5)), comment = 'tiles60 1/5, 50k samples')

fit('oth', max_samples = 50000, blocks = list(block = 'tiles5', classes = c(1, 2)), comment = 'tiles05 1/2, 50k samples')
fit('oth', max_samples = 50000, blocks = list(block = 'tiles10', classes = c(1, 2)), comment = 'tiles10 1/2, 50k samples')
fit('oth', max_samples = 50000, blocks = list(block = 'tiles20', classes = c(1, 2)), comment = 'tiles20 1/2, 50k samples')
fit('oth', max_samples = 50000, blocks = list(block = 'tiles40', classes = c(1, 2)), comment = 'tiles40 1/2, 50k samples')
fit('oth', max_samples = 50000, blocks = list(block = 'tiles60', classes = c(1, 2)), comment = 'tiles60 1/2, 50k samples')




# fit peg with 2025 samples as holdout
sample('peg', result = 'upscale2025', n = 50000)

fit('peg', data = 'field2025', max_samples = 50000, blocks = list(block = 'PEG_2025', classes = 2025), comment = 'peg holdout = 2025, 50k samples')
fit('peg', data = 'field2025', max_samples = 50000, blocks = list(block = 'PEG_2025', classes = 2025), minscore = 5,  comment = 'peg holdout2025, 50k, minscore5')
fit('peg', data = 'field2025', max_samples = 50000, blocks = list(block = 'PEG_2025', classes = 2025), minscore = 6,  comment = 'peg holdout2025, 50k, minscore6')

fit('peg', data = 'field2025', vars = 'ortho, dem | low, mid', max_samples = 50000, blocks = list(block = 'PEG_2025', classes = 2025), comment = 'peg holdout = 2025, 50k samples, no deriv no high')
fit('peg', data = 'field2025', vars = 'ortho, dem | low, mid', max_samples = 50000, blocks = list(block = 'PEG_2025', classes = 2025), minscore = 5,  comment = 'peg holdout2025, 50k, minscore5, no deriv no high')
fit('peg', data = 'field2025', vars = 'ortho, dem | low, mid', max_samples = 50000, blocks = list(block = 'PEG_2025', classes = 2025), minscore = 6,  comment = 'peg holdout2025, 50k, minscore6, no deriv no high')

fit('peg', data = 'field2025', filter = c('ortho | low', 'dem', 'swir'), max_samples = 50000, blocks = list(block = 'PEG_2025', classes = 2025), comment = 'peg holdout = 2025, 50k samples, no deriv')





derive('peg', 'ortho | mica', metrics = c('mean', 'std', 'NDVImean', 'NDVIstd'), window = 3, resources = list(memory = 128))
derive('peg', 'ortho | mica', metrics = c('mean', 'std', 'NDVImean', 'NDVIstd'), window = 5, resources = list(memory = 128))
derive('peg', 'ortho | mica', metrics = c('NDRE', 'NDWIg'), resources = list(memory = 128))
gather('peg', update = FALSE)
gather(c('oth', 'sor', 'wel'))


fit('peg', data = 'field2025', include_classes = 3:5, max_samples = 50000, blocks = list(block = 'PEG_2025', classes = 2025), comment = 'peg holdout = 2025, 50k samples')
fit('peg', data = 'field2025', include_classes = 3:7, max_samples = 50000, blocks = list(block = 'PEG_2025', classes = 2025), comment = 'peg holdout = 2025, 50k samples')
fit('peg', data = 'field2025', include_classes = c(1, 6, 12), max_samples = 50000, blocks = list(block = 'PEG_2025', classes = 2025), comment = 'peg holdout = 2025, 50k samples')


# Make 2025 blocks for oth, sor, wel
sample(c('peg', 'oth', 'sor', 'wel'))
#
# now do 2025 holdout fits




# Let's try a whole lot of derived variables. I timed out on both derive runs, so this is a subset
sample('peg', result = 'upscale2025', n = 50000)


fit('peg', data = 'upscale2025', max_samples = 15000, blocks = list(block = 'tiles20', classes = c(1, 2)), comment = 'tiles20 1/2, 15k samples, upscale')
fit('peg', data = 'upscale2025', max_samples = 15000, blocks = list(block = 'PEG_2025', classes = 2025), comment = 'peg holdout = 2025, 15k samples, upscale')
fit('peg', vars = '{w\\d}', data = 'upscale2025', max_samples = 15000, blocks = list(block = 'tiles20', classes = c(1, 2)), comment = 'tiles20 1/2, 15k samples, upscale')
fit('peg', vars = '{w\\d}', data = 'upscale2025', max_samples = 15000, blocks = list(block = 'PEG_2025', classes = 2025), comment = 'peg holdout = 2025, 15k samples, upscale')


fit('peg', data = 'upscale2025', max_samples = 50000, blocks = list(block = 'tiles20', classes = c(1, 2)), comment = 'tiles20 1/2, 50k samples, upscale')
fit('peg', data = 'upscale2025', max_samples = 50000, blocks = list(block = 'PEG_2025', classes = 2025), comment = 'peg holdout = 2025, 50k samples, upscale')
fit('peg', vars = '{w\\d}', data = 'upscale2025', max_samples = 50000, blocks = list(block = 'tiles20', classes = c(1, 2)), comment = 'tiles20 1/2, 50k samples, upscale')
fit('peg', vars = '{w\\d}', data = 'upscale2025', max_samples = 50000, blocks = list(block = 'PEG_2025', classes = 2025), comment = 'peg holdout = 2025, 50k samples, upscale')


fit('peg', data = 'upscale2025', max_samples = 50000, blocks = list(block = 'tiles20', classes = c(1, 2)), resources = list(walltime = '12:00:00'), comment = 'tiles20 1/2, 50k samples, upscale')
fit('peg', vars = '{w\\d}', data = 'upscale2025', max_samples = 50000, blocks = list(block = 'tiles20', classes = c(1, 2)), resources = list(walltime = '12:00:00'), comment = 'tiles20 1/2, 50k samples, upscale')

fit('peg', data = 'upscale2025', max_samples = 50000, blocks = list(block = 'tiles20', classes = c(1, 5)), resources = list(walltime = '12:00:00'), comment = 'tiles20 1/5, 50k samples, upscale')
fit('peg', data = 'upscale2025', max_samples = 50000, blocks = list(block = 'tiles20', classes = c(2, 6)), resources = list(walltime = '12:00:00'), comment = 'tiles20 2/6, 50k samples, upscale')
fit('peg', data = 'upscale2025', max_samples = 50000, blocks = list(block = 'tiles20', classes = c(4, 8)), resources = list(walltime = '12:00:00'), comment = 'tiles20 4/8, 50k samples, upscale')
fit('peg', comment = 'original overfit, just to make sure nothing changed')
fit('peg', data = 'upscale2025', comment = 'original overfit, 2025 data')

derive('peg', 'swir | low, mid', metrics = c('mean', 'std'), window = 3, resources = list(memory = 128))
derive('peg', 'swir | low, mid', metrics = c('mean', 'std'), window = 5, resources = list(memory = 128))

fit('peg', data = 'upscale2025', include_classes = 3:7, max_samples = 50000, blocks = list(block = 'tiles20', classes = c(1, 5)), resources = list(walltime = '12:00:00'), comment = 'tiles20 1/5, 50k samples, upscale, classes 3:7')
fit('peg', data = 'upscale2025', include_classes = 3:7, max_samples = 50000, blocks = list(block = 'tiles20', classes = c(2, 6)), resources = list(walltime = '12:00:00'), comment = 'tiles20 2/6, 50k samples, upscale, classes 3:7')
fit('peg', data = 'upscale2025', include_classes = 3:7, max_samples = 50000, blocks = list(block = 'tiles20', classes = c(4, 8)), resources = list(walltime = '12:00:00'), comment = 'tiles20 4/8, 50k samples, upscale, classes 3:7')


fit('peg', data = 'upscale2025', comment = 'original overfit, 2025 data', resources = list(walltime = '12:00:00'))

derive('peg', 'swir | low, mid', metrics = c('mean', 'std'), window = 7, resources = list(memory = 128))
derive('peg', 'swir | low, mid', metrics = c('mean', 'std'), window = 9, resources = list(memory = 128))

sample('peg', result = 'more2025', n = 50000)            # more upscaling with additional vars


# try these again after building package ..........
top20vars <- c('ortho_swir_summer_2020_mid.in', 'ortho_swir_summer_2021_mid', 'dem_mica_fall_2020_mid', 'ortho_swir_spring_2021_mid', 'dem_rgb_spring_2019_low', 'dem_mica_spring_2022_mid', 'derived_mica_summer_2020_high_ndwig', 'dem_mavic_spring_2021_low', 'dem_mica_summer_2019_mid', 'dem_mica_post_2020_mid', 'dem_mica_spring_2019_low', 'dem_mica_spring_2021_low', 'dem_mica_fall_2018_mid', 'ortho_swir_summer_2022_high', 'dem_p4_spring_2022_low', 'ortho_swir_fall_2022_high.spring', 'dem_p4_post_2019_low', 'dem_mica_summer_2019_low', 'derived_mica_post_2019_high_mean.w5', 'derived_mica_summer_2020_high_ndvi')
fit('peg', data = 'upscale2025', vars = top20vars, max_samples = 15000, blocks = list(block = 'tiles20', classes = c(1, 2)), resources = list(walltime = '12:00:00'), comment = 'tiles20 1/2, 30k samples, upscale, classes 3:7')
fit('peg', data = 'upscale2025', vars = top20vars, max_samples = 15000, blocks = list(block = 'tiles20', classes = c(1, 5)), resources = list(walltime = '12:00:00'), comment = 'tiles20 1/5, 30k samples, upscale, classes 3:7')
fit('peg', data = 'upscale2025', vars = top20vars, max_samples = 15000, blocks = list(block = 'tiles20', classes = c(2, 6)), resources = list(walltime = '12:00:00'), comment = 'tiles20 2/6, 30k samples, upscale, classes 3:7')
fit('peg', data = 'upscale2025', vars = top20vars, max_samples = 15000, blocks = list(block = 'tiles20', classes = c(4, 8)), resources = list(walltime = '12:00:00'), comment = 'tiles20 4/8, 30k samples, upscale, classes 3:7')



# test new poly holdout approach
gather('peg', replace_ground_truth = TRUE, replace_caches = FALSE, local = TRUE)
sample('peg', vars = 'ortho | mica | fall | mid', n = 100, result = 'new', local = TRUE)

sample('peg', n = 50e10, result = 'new', resources = list(walltime = '10:00:00'))


# and then
fit('peg', data = 'new', max_samples = 15000, blocks = list(block = 'bypoly01', classes = c(1, 6)), comment = 'bypoly01 15k upscale')
fit('peg', data = 'new', max_samples = 15000, blocks = list(block = 'bypoly02', classes = c(1, 6)), comment = 'bypoly02 15k upscale')
fit('peg', data = 'new', max_samples = 15000, blocks = list(block = 'bypoly03', classes = c(1, 6)), comment = 'bypoly03 15k upscale')
fit('peg', data = 'new', max_samples = 15000, blocks = list(block = 'bypoly04', classes = c(1, 6)), comment = 'bypoly04 15k upscale')
fit('peg', data = 'new', max_samples = 15000, blocks = list(block = 'bypoly05', classes = c(1, 6)), comment = 'bypoly05 15k upscale')

fit('peg', data = 'new', max_samples = 50000, blocks = list(block = 'bypoly01', classes = c(1, 6)), resources = list(walltime = '12:00:00'), comment = 'bypoly01 50k upscale')

fit('peg', data = 'new', exclude_vars = 'swir', max_samples = 15000, blocks = list(block = 'bypoly01', classes = c(1, 6)), comment = 'bypoly01 15k upscale no swir')




fit('peg', data = 'new', vars = 'mica | spring | low', max_samples = 10000, blocks = list(block = 'bypoly01', classes = c(1, 6)), notune = TRUE, comment = 'tuning test 1', local = TRUE)
fit('peg', data = 'new', vars = 'mica | spring | low', max_samples = 10000, bypoly = 'bypoly03', notune = TRUE, comment = 'tuning test 4', local = TRUE)


# top 65 vars for fit 1391
vars1391 <- c('dem_mica_fall_2020_mid', 'dem_mica_spring_2022_mid', 'dem_mavic_spring_2021_low', 'dem_mica_summer_2019_mid', 'dem_rgb_spring_2019_low', 'ortho_swir_spring_2021_mid', 'dem_mica_spring_2019_low', 'ortho_swir_summer_2022_high', 'ortho_swir_summer_2021_mid', 'derived_mica_summer_2020_high_ndwig', 'ortho_swir_summer_2020_mid.in', 'dem_mica_fall_2018_mid', 'dem_mica_post_2020_mid', 'dem_mica_spring_2021_low', 'derived_mica_summer_2020_high_ndre', 'dem_p4_spring_2022_low', 'derived_mica_spring_2021_mid_mean.w5', 'dem_mica_summer_2020_mid.in', 'derived_mica_summer_2020_high_ndvi', 'ortho_swir_fall_2022_high.spring', 'derived_mica_spring_2021_mid_mean.w3', 'dem_mica_summer_2019_low', 'ortho_swir_summer_2020_high', 'dem_mica_summer_2022_mid', 'derived_mica_post_2019_high_mean.w5', 'dem_mica_fall_2022_mid', 'ortho_mica_spring_2021_mid', 'dem_p4_post_2019_low', 'derived_mica_fall_2020_high.spring_mean.w5', 'dem_mica_summer_2021_mid', 'derived_mica_post_2020_high.spring_mean.w5', 'derived_mica_spring_2021_mid_mean.w5', 'derived_mica_post_2020_mid_ndvi', 'ortho_swir_spring_2021_high', 'derived_mica_spring_2022_mid_mean.w5', 'derived_mica_post_2019_high_mean.w5', 'derived_mica_summer_2021_mid_mean.w5', 'derived_mica_spring_2022_mid_ndwig', 'derived_mica_post_2020_high.spring_mean.w3', 'derived_mica_post_2020_mid_ndwig', 'derived_mica_summer_2019_mid_mean.w5', 'derived_mica_spring_2021_mid_mean.w3', 'derived_mica_post_2020_mid_mean.w5', 'derived_mica_summer_2020_high_mean.w5', 'derived_mica_summer_2021_mid_mean.w5', 'dem_mavic_summer_2021_mid', 'derived_mica_fall_2020_high.spring_mean.w5', 'derived_mica_fall_2020_high.spring_mean.w3', 'derived_mica_post_2019_high_mean.w3', 'derived_mica_spring_2022_mid_mean.w3', 'derived_mica_summer_2020_mid.in_mean.w5', 'derived_mica_post_2019_high_mean.w3', 'derived_mica_spring_2021_low_mean.w5', 'derived_mica_fall_2020_high.spring_ndre', 'derived_mica_spring_2022_mid_ndre', 'derived_mica_spring_2021_low_mean.w5', 'derived_mica_post_2019_high_mean.w5', 'derived_mica_spring_2021_low_mean.w5', 'derived_mica_summer_2019_mid_mean.w5', 'ortho_mica_spring_2021_mid', 'derived_mica_fall_2020_high.spring_mean.w5', 'derived_mica_summer_2020_high_mean.w3', 'derived_mica_summer_2019_mid_ndvi', 'derived_mica_fall_2022_mid_mean.w5', 'derived_mica_summer_2020_mid.in_mean.w3', 'derived_mica_post_2020_mid_mean.w5', 'derived_mica_summer_2021_mid_mean.w3', 'ortho_swir_spring_2021_low', 'derived_mica_spring_2021_mid_mean.w5', 'ortho_mica_spring_2022_mid', 'derived_mica_summer_2022_mid_mean.w5', 'derived_mica_post_2020_mid_mean.w3', 'derived_mica_fall_2020_high.spring_ndvi', 'derived_mica_summer_2022_mid_mean.w5', 'ortho_mica_summer_2020_mid.out', 'derived_mica_fall_2020_high.spring_mean.w3', 'derived_mica_summer_2019_low_mean.w5', 'derived_mica_summer_2019_mid_mean.w3', 'derived_mica_summer_2022_mid_mean.w5', 'derived_mica_summer_2019_mid_ndre', 'derived_mica_spring_2021_low_mean.w5', 'ortho_mica_summer_2021_mid', 'derived_mica_summer_2021_mid_mean.w3', 'derived_mica_summer_2020_mid.in_mean.w5', 'derived_mica_post_2019_high_mean.w5', 'derived_mica_summer_2022_mid_mean.w5', 'derived_mica_summer_2021_high_mean.w5', 'derived_mica_spring_2021_mid_mean.w5', 'derived_mica_spring_2021_mid_mean.w5')

fit('peg', data = 'new', vars = vars1391, max_samples = 15000, bypoly = 'bypoly01', notune = TRUE, comment = 'bypoly01 15k upscale 65 vars notune')
fit('peg', data = 'new', vars = vars1391, max_samples = 15000, bypoly = 'bypoly02', notune = TRUE, comment = 'bypoly02 15k upscale 65 vars notune')
fit('peg', data = 'new', vars = vars1391, max_samples = 15000, bypoly = 'bypoly03', notune = TRUE, comment = 'bypoly03 15k upscale 65 vars notune')
fit('peg', data = 'new', vars = vars1391, max_samples = 15000, bypoly = 'bypoly04', notune = TRUE, comment = 'bypoly04 15k upscale 65 vars notune')
fit('peg', data = 'new', vars = vars1391, max_samples = 15000, bypoly = 'bypoly05', notune = TRUE, comment = 'bypoly05 15k upscale 65 vars notune')

# top 20 from previous fit
vars20 <- c('ortho_swir_spring_2021_mid', 'derived_mica_fall_2020_high.spring_mean.w5', 'derived_mica_spring_2021_mid_mean.w5', 'derived_mica_post_2020_high.spring_mean.w5', 'derived_mica_fall_2020_high.spring_mean.w3', 'derived_mica_spring_2021_mid_mean.w3', 'derived_mica_fall_2020_high.spring_ndvi', 'ortho_swir_summer_2020_mid.in', 'ortho_mica_spring_2021_mid', 'derived_mica_post_2020_high.spring_mean.w3', 'derived_mica_fall_2020_high.spring_ndre', 'ortho_mica_summer_2020_mid.out', 'derived_mica_spring_2021_mid_mean.w5', 'derived_mica_summer_2020_mid.in_mean.w5', 'derived_mica_summer_2019_mid_mean.w5', 'dem_mica_fall_2020_mid', 'ortho_mica_summer_2020_mid.out', 'derived_mica_spring_2021_low_mean.w5', 'derived_mica_summer_2020_high_mean.w5', 'derived_mica_spring_2021_mid_mean.w3')
fit('peg', data = 'new', vars = vars20, max_samples = 15000, bypoly = 'bypoly01', notune = TRUE, comment = 'bypoly01 15k upscale 20 vars notune')
fit('peg', data = 'new', vars = vars20, max_samples = 15000, bypoly = 'bypoly02', notune = TRUE, comment = 'bypoly02 15k upscale 20 vars notune')
fit('peg', data = 'new', vars = vars20, max_samples = 15000, bypoly = 'bypoly03', notune = TRUE, comment = 'bypoly03 15k upscale 20 vars notune')
fit('peg', data = 'new', vars = vars20, max_samples = 15000, bypoly = 'bypoly04', notune = TRUE, comment = 'bypoly04 15k upscale 20 vars notune')
fit('peg', data = 'new', vars = vars20, max_samples = 15000, bypoly = 'bypoly05', notune = TRUE, comment = 'bypoly05 15k upscale 20 vars notune')

# 23 vars that seem reasonable; nothing derived
vars23 <- 'ortho | mica | low, mid + dem | spring, fall, post | low'
fit('peg', data = 'new', vars = vars23, max_samples = 15000, bypoly = 'bypoly01', notune = TRUE, comment = 'bypoly01 15k upscale 23 vars notune')
fit('peg', data = 'new', vars = vars23, max_samples = 15000, bypoly = 'bypoly02', notune = TRUE, comment = 'bypoly02 15k upscale 23 vars notune')
fit('peg', data = 'new', vars = vars23, max_samples = 15000, bypoly = 'bypoly03', notune = TRUE, comment = 'bypoly03 15k upscale 23 vars notune')
fit('peg', data = 'new', vars = vars23, max_samples = 15000, bypoly = 'bypoly04', notune = TRUE, comment = 'bypoly04 15k upscale 23 vars notune')
fit('peg', data = 'new', vars = vars23, max_samples = 15000, bypoly = 'bypoly05', notune = TRUE, comment = 'bypoly05 15k upscale 23 vars notune')




gather('wel', replace_ground_truth = TRUE)
gather('rr', replace_ground_truth = TRUE)
gather('oth', replace_ground_truth = TRUE)


fit('peg', data = 'new', minscore = 4, max_samples = 15000, bypoly = 'bypoly01', notune = TRUE, comment = 'bypoly01 15k upscale minscore=4 notune')
fit('peg', data = 'new', minscore = 4, max_samples = 15000, bypoly = 'bypoly02', notune = TRUE, comment = 'bypoly02 15k upscale minscore=4 notune')
fit('peg', data = 'new', minscore = 4, max_samples = 15000, bypoly = 'bypoly03', notune = TRUE, comment = 'bypoly03 15k upscale minscore=4 notune')
fit('peg', data = 'new', minscore = 4, max_samples = 15000, bypoly = 'bypoly04', notune = TRUE, comment = 'bypoly04 15k upscale minscore=4 notune')
fit('peg', data = 'new', minscore = 4, max_samples = 15000, bypoly = 'bypoly05', notune = TRUE, comment = 'bypoly05 15k upscale minscore=4 notune')

fit('peg', data = 'new', minscore = 4, max_samples = 15000, bypoly = 'bypoly01', comment = 'bypoly01 15k upscale minscore=4')

fit('peg', data = 'new', vars = '13May21_PEG_Low_Mavic_Ortho.tif', max_samples = 15000, bypoly = 'bypoly01', notune = TRUE, comment = 'just one good ortho')



# now...
fit('peg', data = 'new', vars = '13May21_PEG_Low_Mavic_Ortho.tif', max_samples = 15000, bypoly = 'bypoly01', notune = TRUE, comment = 'just one good ortho')
afewpegs <- '13May21_PEG_Low_Mavic_Ortho.tif + derived_mica_summer_2019_low_ndvi + derived_mica_summer_2019_low_ndre + derived_mica_summer_2019_low_mean.w3 + derived_mica_summer_2019_low_mean.w5 + 25Jul19_PEG_Low_Mica_Ortho__NDVImean_w3.tif + 25Jul19_PEG_Low_Mica_Ortho__NDVImean_w5.tif + derived_mica_summer_2019_low_std.w5'
fit('peg', data = 'new', vars = afewpegs, max_samples = 15000, bypoly = 'bypoly01', notune = TRUE, comment = 'a few good orthos')

fit('peg', data = 'new', vars = vars23, max_samples = 50000, bypoly = 'bypoly01', comment = 'bypoly01 50k upscale 23 vars with tuning (again ... >1 hr)')



# next....

for(win in c(3, 5, 7, 9, 11, 13)) {
   derive('peg', 'ortho, dem | mica | low', metrics = c('mean', 'std'), window = win, cache = TRUE, resources = list(memory = 128), comment = 'make more mica means')
   derive('rr', 'ortho, dem | mica | low', metrics = c('mean', 'std'), window = win, cache = TRUE, resources = list(memory = 128))
   derive('oth', 'ortho, dem | mica | summer, fall | low', metrics = c('mean', 'std'), window = win, cache = TRUE, resources = list(memory = 128))
   derive('wel', 'ortho, dem | mica | low', metrics = c('mean', 'std'), window = win, cache = TRUE, resources = list(memory = 128))
}


# OOM cleanups:
for(win in c(3, 5, 7, 9, 11, 13))
   derive('oth', 'ortho, dem | mica | summer, fall | low', metrics = c('mean', 'std'), window = win, cache = TRUE, resources = list(memory = 200))








sample('rr', result = 'deriv', n = 50000)
sample('wel', result = 'deriv', n = 50000)


fit('wel', data = 'deriv', max_samples = 15000, bypoly = 'bypoly01', notune = TRUE, comment = 'bypoly01 15k upscale notune')
fit('wel', data = 'deriv', max_samples = 15000, bypoly = 'bypoly02', notune = TRUE, comment = 'bypoly02 15k upscale notune')
fit('wel', data = 'deriv', max_samples = 15000, bypoly = 'bypoly03', notune = TRUE, comment = 'bypoly03 15k upscale notune')



# when sample runs are done
fit('rr', data = 'deriv', max_samples = 15000, bypoly = 'bypoly01', notune = TRUE, comment = 'bypoly01 15k upscale notune')
fit('rr', data = 'deriv', max_samples = 15000, bypoly = 'bypoly02', notune = TRUE, comment = 'bypoly02 15k upscale notune')
fit('rr', data = 'deriv', max_samples = 15000, bypoly = 'bypoly03', notune = TRUE, comment = 'bypoly03 15k upscale notune')




# when derive runs are done...
sample('oth', result = 'deriv', n = 50000)
sample('peg', result = 'deriv', n = 50000)


# THIS IS WHERE WE ARE


# when sample OTH is done
fit('oth', data = 'new', minscore = 5, max_samples = 15000, bypoly = 'bypoly01', notune = TRUE, comment = 'bypoly01 15k upscale minscore=5 notune')
fit('oth', data = 'new', minscore = 5, max_samples = 15000, bypoly = 'bypoly02', notune = TRUE, comment = 'bypoly02 15k upscale minscore=5 notune')
fit('oth', data = 'new', minscore = 5, max_samples = 15000, bypoly = 'bypoly03', notune = TRUE, comment = 'bypoly03 15k upscale minscore=5 notune')


# after I fix drop_corr
# sample('rr', result = 'new_uc', n = 50000, drop_cor = 0.7)
# sample('oth', result = 'new_uc', n = 50000, drop_cor = 0.7)
# sample('wel', result = 'new_uc', n = 50000, drop_cor = 0.7)
# sample('peg', result = 'new_uc', n = 50000, drop_cor = 0.7)

# Try better fits
fit('rr', data = 'deriv', max_samples = 50000, bypoly = 'bypoly01', comment = 'bypoly01 50k upscale')
fit('rr', data = 'deriv', max_samples = 50000, bypoly = 'bypoly02', comment = 'bypoly02 50k upscale')
fit('rr', data = 'deriv', max_samples = 50000, bypoly = 'bypoly03', comment = 'bypoly03 50k upscale')
fit('wel', data = 'deriv', max_samples = 50000, bypoly = 'bypoly01', comment = 'bypoly01 50k upscale minscore=5')
fit('wel', data = 'deriv', max_samples = 50000, bypoly = 'bypoly02', comment = 'bypoly02 50k upscale minscore=5')
fit('wel', data = 'deriv', max_samples = 50000, bypoly = 'bypoly03', comment = 'bypoly03 50k upscale minscore=5')




# 2025 holdout - 15k notune
fit('rr', data = 'deriv', max_samples = 15000, notune = TRUE, blocks = list(block = '_year', classes = 2025), comment = '2025 15k upscale notune')
fit('rr', data = 'deriv', max_samples = 15000, notune = TRUE, blocks = list(block = '_year', classes = 2025), comment = '2025 15k upscale notune')
fit('rr', data = 'deriv', max_samples = 15000, notune = TRUE, blocks = list(block = '_year', classes = 2025), comment = '2025 15k upscale notune')
fit('wel', data = 'deriv', max_samples = 15000, notune = TRUE, blocks = list(block = '_year', classes = 2025), comment = '2025 15k upscale notune')
fit('wel', data = 'deriv', max_samples = 15000, notune = TRUE, blocks = list(block = '_year', classes = 2025), comment = '2025 15k upscale notune')
fit('wel', data = 'deriv', max_samples = 15000, notune = TRUE, blocks = list(block = '_year', classes = 2025), comment = '2025 15k upscale notune')


# 2025 holdout - 50k
fit('rr', data = 'deriv', max_samples = 50000, blocks = list(block = '_year', classes = 2025), comment = '2025 50k upscale')
fit('rr', data = 'deriv', max_samples = 50000, blocks = list(block = '_year', classes = 2025), comment = '2025 50k upscale')
fit('rr', data = 'deriv', max_samples = 50000, blocks = list(block = '_year', classes = 2025), comment = '2025 50k upscale')
fit('wel', data = 'deriv', max_samples = 50000, blocks = list(block = '_year', classes = 2025), comment = '2025 50k upscale minscore=5')
fit('wel', data = 'deriv', max_samples = 50000, blocks = list(block = '_year', classes = 2025), comment = '2025 50k upscale minscore=5')
fit('wel', data = 'deriv', max_samples = 50000, blocks = list(block = '_year', classes = 2025), comment = '2025 50k upscale minscore=5')


# *** Errors
# *** derive for peg 11, 13 and oth 11, 13 timed out after 4 hours
# *** sample for oth failed on [rast] file does not exist: .../flights/NA
# *** 2025 50k upscale minscore=5 for wel timed out at 5 hours. Have 2 others though.
# *** all 3 2025 50k upscale for rr timed out at 5 hours.


# got an error in sample, fix it and then do these
sample('oth', result = 'deriv', n = 50000)

fit('oth', data = 'deriv', minscore = 5, max_samples = 15000, notune = TRUE, blocks = list(block = '_year', classes = 2025), comment = '2025 15k upscale minscore=5 notune')
fit('oth', data = 'deriv', minscore = 5, max_samples = 15000, notune = TRUE, blocks = list(block = '_year', classes = 2025), comment = '2025 15k upscale minscore=5 notune')
fit('oth', data = 'deriv', minscore = 5, max_samples = 15000, notune = TRUE, blocks = list(block = '_year', classes = 2025), comment = '2025 15k upscale minscore=5 notune')

fit('oth', data = 'deriv', minscore = 5, max_samples = 50000, blocks = list(block = '_year', classes = 2025), comment = '2025 50k upscale minscore=5')
fit('oth', data = 'deriv', minscore = 5, max_samples = 50000, blocks = list(block = '_year', classes = 2025), comment = '2025 50k upscale minscore=5')
fit('oth', data = 'deriv', minscore = 5, max_samples = 50000, blocks = list(block = '_year', classes = 2025), comment = '2025 50k upscale minscore=5')

fit('oth', data = 'deriv', minscore = 5, max_samples = 50000, bypoly = 'bypoly01', comment = 'bypoly01 50k upscale minscore=5')
fit('oth', data = 'deriv', minscore = 5, max_samples = 50000, bypoly = 'bypoly02', comment = 'bypoly02 50k upscale minscore=5')
fit('oth', data = 'deriv', minscore = 5, max_samples = 50000, bypoly = 'bypoly03', comment = 'bypoly03 50k upscale minscore=5')


#################
# flip experiment

vars <- 'dem_mica_fall_2020_mid + ortho_swir_summer_2022_high + dem_mica_fall_2018_mid + dem_mica_summer_2019_mid + ortho_swir_summer_2021_mid + dem_mica_spring_2021_low + dem_p4_spring_2022_low + ortho_swir_spring_2021_high + dem_mica_spring_2019_low + dem_rgb_spring_2019_low'

# make flipped versions
library(terra)
library(stringr)

path <- '/work/pi_cschweik_umass_edu/marsh_mapping/data/peg/flights/'
toflip <- find_orthos('peg', vars)$file
flipped <- do.call(paste0, list('flipped', 1:10, '.tif'))
flippedvars <- paste(str_extract(flipped, '(.*)(.tif$)', group = 1), collapse = ' + ')


for(i in 2:10) {     #  seq_along(toflip)) {
   print(i)
   x <- flip(rast(file.path(path, toflip[i])), direction = 'horizontal')
   writeRaster(x, file.path(path, flipped[i]))
}

x <- build_flights_db('peg')
sample('peg', result = 'flip', n = 50000, vars = paste0(vars, ' + ', flippedvars))



# when sample is done
fit('peg', data = 'flip', vars = vars, bypoly = 'bypoly01', notune = TRUE, comment = 'flip test: toflip')
fit('peg', data = 'flip', vars = flippedvars, bypoly = 'bypoly01', notune = TRUE, comment = 'flip test: flipped')
fit('peg', data = 'flip', vars = paste0(vars, ' + ', flippedvars), bypoly = 'bypoly01', notune = TRUE, comment = 'flip test: both')

fit('peg', data = 'flip', vars = vars, bypoly = 'bypoly01', max_samples = 50e3, notune = FALSE, comment = 'flip test: toflip 50k+', resources = list(walltime = '12:00:00'))
fit('peg', data = 'flip', vars = flippedvars, bypoly = 'bypoly01', max_samples = 50e3, notune = FALSE, comment = 'flip test: flipped 50k+', resources = list(walltime = '12:00:00'))
fit('peg', data = 'flip', vars = paste0(vars, ' + ', flippedvars), bypoly = 'bypoly01', max_samples = 50e3, notune = FALSE, comment = 'flip test: both 50k+', resources = list(walltime = '12:00:00'))

#################




#################
# try without 2025
# omit emphemeral classes
# both
# compare with fits 1467:1469 (CCRs = 21.9%, 22.7%, 20.7%)

fit('peg', data = 'deriv', max_samples = 15000, bypoly = 'bypoly01', notune = TRUE, exclude_year = 2025, comment = 'bypoly01 omit 2025')
fit('peg', data = 'deriv', max_samples = 15000, bypoly = 'bypoly02', notune = TRUE, exclude_year = 2025, comment = 'bypoly02 omit 2025')
fit('peg', data = 'deriv', max_samples = 15000, bypoly = 'bypoly03', notune = TRUE, exclude_year = 2025, comment = 'bypoly03 omit 2025')

fit('peg', data = 'deriv', max_samples = 15000, bypoly = 'bypoly01', notune = TRUE, exclude_year = 2025, comment = 'bypoly01 omit 2025')
fit('peg', data = 'deriv', max_samples = 15000, bypoly = 'bypoly02', notune = TRUE, exclude_classes = c(10, 15, 30, 31, 32, 33), comment = 'bypoly02 noephemeral')
fit('peg', data = 'deriv', max_samples = 15000, bypoly = 'bypoly03', notune = TRUE, exclude_classes = c(10, 15, 30, 31, 32, 33), comment = 'bypoly03 noephemeral')

fit('peg', data = 'deriv', max_samples = 15000, bypoly = 'bypoly02', notune = TRUE, exclude_year = 2025, exclude_classes = c(10, 15, 30, 31, 32, 33), comment = 'bypoly02 omit 2025 noephemeral')
fit('peg', data = 'deriv', max_samples = 15000, bypoly = 'bypoly03', notune = TRUE, exclude_year = 2025, exclude_classes = c(10, 15, 30, 31, 32, 33), comment = 'bypoly03 omit 2025 noephemeral')



fit('peg', data = 'deriv', max_samples = 50e3, bypoly = 'bypoly05', notune = FALSE, exclude_year = 2025, comment = 'bypoly01 omit 2025 50k+', resources = list(walltime = '12:00:00'))
fit('peg', data = 'deriv', max_samples = 50e3, bypoly = 'bypoly05', notune = FALSE, exclude_year = 2025, comment = 'bypoly01 omit 2025 50k+', resources = list(walltime = '12:00:00'))
fit('peg', data = 'deriv', max_samples = 50e3, bypoly = 'bypoly05', notune = FALSE, exclude_year = 2025, exclude_classes = c(10, 15, 30, 31, 32, 33), comment = 'bypoly01 omit 2025 noephemeral 50k+', resources = list(walltime = '12:00:00'))




################# NEW UPSCALING APPROACH

#upscale_clone('oth', 'oth_1m', 1)
#sample('oth_1m', p = 1, balance = FALSE)


upscale_clone('oth', 'oth_50cm', 0.5)
upscale_clone('peg', 'peg_1m', 1)
upscale_clone('peg', 'peg_50cm', 0.5)




fit('oth_1m', bypoly = 'bypoly01', min_class = 50, comment = 'oth 1m bypoly01')
fit('oth_1m', bypoly = 'bypoly02', min_class = 50, comment = 'oth 1m bypoly02')
fit('oth_1m', bypoly = 'bypoly03', min_class = 50, comment = 'oth 1m bypoly03')
fit('oth_1m', bypoly = 'bypoly04', min_class = 50, comment = 'oth 1m bypoly04')
fit('oth_1m', bypoly = 'bypoly05', min_class = 50, comment = 'oth 1m bypoly05')
fit('oth_1m', byyear = 2025, min_class = 50)








# when upscale_clone is done
sample('oth_50cm', p = 1, balance = FALSE)
sample('peg_1m', p = 1, balance = FALSE)
sample('peg_50cm', p = 1, balance = FALSE)


# when sample is done
fit('oth_50cm', bypoly = 'bypoly01', min_class = 100, comment = 'oth 50cm bypoly01')
fit('oth_50cm', bypoly = 'bypoly02', min_class = 100, comment = 'oth 50cm bypoly02')
fit('oth_50cm', bypoly = 'bypoly03', min_class = 100, comment = 'oth 50cm bypoly03')
fit('oth_50cm', bypoly = 'bypoly04', min_class = 100, comment = 'oth 50cm bypoly04')
fit('oth_50cm', bypoly = 'bypoly05', min_class = 100, comment = 'oth 50cm bypoly05')
fit('oth_50cm', byyear = 2025, classes = 2025, min_class = 100)


fit('peg_1m', bypoly = 'bypoly01', min_class = 50, comment = 'peg 1m bypoly01')
fit('peg_1m', bypoly = 'bypoly02', min_class = 50, comment = 'peg 1m bypoly02')
fit('peg_1m', bypoly = 'bypoly03', min_class = 50, comment = 'peg 1m bypoly03')
fit('peg_1m', bypoly = 'bypoly04', min_class = 50, comment = 'peg 1m bypoly04')
fit('peg_1m', bypoly = 'bypoly05', min_class = 50, comment = 'peg 1m bypoly05')
fit('peg_1m', byyear = 2025, min_class = 50)


fit('peg_50cm', bypoly = 'bypoly01', min_class = 100, comment = 'peg 50cm bypoly01')
fit('peg_50cm', bypoly = 'bypoly02', min_class = 100, comment = 'peg 50cm bypoly02')
fit('peg_50cm', bypoly = 'bypoly03', min_class = 100, comment = 'peg 50cm bypoly03')
fit('peg_50cm', bypoly = 'bypoly04', min_class = 100, comment = 'peg 50cm bypoly04')
fit('peg_50cm', bypoly = 'bypoly05', min_class = 100, comment = 'peg 50cm bypoly05')
fit('peg_50cm', byyear = 2025, min_class = 100)




