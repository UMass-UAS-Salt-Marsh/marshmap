gather('oth')

screen()

derive('oth', c('mica_spring_2021_mid', 'mica_spring_2022_mid'), metrics = 'NDVI')
derive('oth', 'mica_spring_2022_mid_mean', metrics = 'mean', window = 5)

sample('oth', n = 10000, result = 'all_vars_10000')

fit('oth', 'all_vars_10000')

map(136, clip = c(-70.86254419, -70.86135362, 42.77072136, 42.7717978))    # small clip
map(136, clip = c(-70.86452506, -70.86040917, 42.76976948, 42.77283781))   # medium clip
map(136, resources = list(memory = 400))
