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
fit('peg', vars = 'derived', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles20', classes = c(1, 5)), comment = 'tiles20 1/5, 50k samples, DERIVED')
fit('peg', vars = 'derived', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles40', classes = c(1, 5)), comment = 'tiles40 1/5, 50k samples, DERIVED')
fit('peg', vars = 'derived', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles20', classes = c(1, 2)), comment = 'tiles20 1/2, 50k samples, DERIVED')
fit('peg', vars = 'derived', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles40', classes = c(1, 2)), comment = 'tiles40 1/2, 50k samples, DERIVED')
fit('oth', vars = 'derived', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles20', classes = c(1, 5)), comment = 'tiles20 1/5, 50k samples, DERIVED')
fit('oth', vars = 'derived', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles40', classes = c(1, 5)), comment = 'tiles40 1/5, 50k samples, DERIVED')
fit('oth', vars = 'derived', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles20', classes = c(1, 2)), comment = 'tiles20 1/2, 50k samples, DERIVED')
fit('oth', vars = 'derived', max_samples = 50000, data = 'deriv', blocks = list(block = 'tiles40', classes = c(1, 2)), comment = 'tiles40 1/2, 50k samples, DERIVED')




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
