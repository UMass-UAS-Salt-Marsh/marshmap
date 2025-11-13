

plot(x$tile, x$ccr, pch = 19, col = as.factor(x$cells))
lines(oth$Group.2, oth$x, col = 'blue')
lines(peg$Group.2, peg$x, col = 'orange')



# from this mess


# x <- fitinfo(quiet = TRUE)
# 
# y <- x[, c('id', 'site', 'CCR', 'comment_launch')]
# 
# x <- y
# 
# i <- grep('^tiles', x$comment_launch)
# 
# x <- x[1:89,]
# x <- x[!grepl('DERIVED', x$comment_launch), ]
# x <- x[!grepl('excluding bad', x$comment_launch), ]
# x <- x[!grepl('max.depth', x$comment_launch), ]
# 
# 
# x$tile <- str_extract(x$comment_launch, '(tiles)(\\d*)', group = 2)
# x$cells <- str_extract(x$comment_launch, '\\d/\\d')
# x$fitid <- str_extract(x$comment_launch, '(fit )(\\d*)', group = 2)
# x$fitid <- as.numeric(x$fitid)
# x$tile <- as.numeric(x$tile)
# x$ccr <- as.numeric(str_extract(x$CCR, '\\d*\\.\\d'))
# 
# saveRDS(x, '/work/pi_cschweik_umass_edu/marsh_mapping/rds/tilesearch.RDS')



x <- readRDS('/work/pi_cschweik_umass_edu/marsh_mapping/rds/tilesearch.RDS')
y <- aggreg(x$ccr, by = list(x$site, x$tile), FUN = 'mean', drop_by = FALSE)


oth <- y[y$Group.1 == 'oth',]


plot(x$tile, x$ccr, pch = 19, col = as.factor(x$cells))
lines(oth$Group.2, oth$x, col = 'blue')
peg <- y[y$Group.1 == 'peg',]
lines(peg$Group.2, peg$x, col = 'orange')



p <- x[x$site == 'peg', ]
plot(p$tile, p$ccr, pch = 19, col = as.factor(x$cells))           # just PEG
peg <- y[y$Group.1 == 'peg',]
lines(peg$Group.2, peg$x, col = 'orange')


o <- x[x$site == 'oth', ]
plot(o$tile, o$ccr, pch = 19, col = as.factor(o$cells))           # just OTH
oth <- y[y$Group.1 == 'oth',]
lines(oth$Group.2, oth$x, col = 'blue')
