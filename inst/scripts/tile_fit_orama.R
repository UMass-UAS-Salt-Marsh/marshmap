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
gather('peg', replace_ground_truth = TRUE, replace_caches = FALSE)
sample('peg', vars = 'ortho | mica | fall | mid', n = 100, result = 'zzzjunk', local = TRUE)

