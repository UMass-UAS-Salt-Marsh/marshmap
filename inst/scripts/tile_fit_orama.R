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
fit('peg', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles20', classes = c(1, 5)), comment = 'tiles20 1/5, 50k samples')
fit('peg', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles40', classes = c(1, 5)), comment = 'tiles40 1/5, 50k samples')
fit('peg', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles20', classes = c(1, 2)), comment = 'tiles20 1/2, 50k samples')
fit('peg', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles40', classes = c(1, 2)), comment = 'tiles40 1/2, 50k samples')
fit('oth', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles20', classes = c(1, 5)), comment = 'tiles20 1/5, 50k samples')
fit('oth', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles40', classes = c(1, 5)), comment = 'tiles40 1/5, 50k samples')
fit('oth', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles20', classes = c(1, 2)), comment = 'tiles20 1/2, 50k samples')
fit('oth', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles40', classes = c(1, 2)), comment = 'tiles40 1/2, 50k samples')




# --- play with max.depth            GOTTA CHANGE fit to allow this...
fit('peg', max_samples = 50000, blocks = list(block = 'tiles40', classes = c(1, 2)), max.depth = 5, comment = 'tiles40 1/2, 50k samples, max.depth = 5')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles40', classes = c(1, 2)), max.depth = 10, comment = 'tiles40 1/2, 50k samples, max.depth = 10')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles40', classes = c(1, 2)), max.depth = 15, comment = 'tiles40 1/2, 50k samples, max.depth = 15')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles40', classes = c(1, 2)), max.depth = 20, comment = 'tiles40 1/2, 50k samples, max.depth = 20')
fit('peg', max_samples = 50000, blocks = list(block = 'tiles40', classes = c(1, 2)), max.depth = 30, comment = 'tiles40 1/2, 50k samples, max.depth = 30')
