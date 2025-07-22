depth <- function(this)                                                             # get depth of a list
   ifelse(is.list(this), 1L + max(sapply(this, depth)), 0L)

info <- function(str) {
   x <- search_names(str)
   cat('\n\n', str, '\n')
   cat('depth = ', depth(x), '\n')
   print(x)
   invisible(x)
}

a1 <- info('mica | mid-out, low')       # has mod
a2 <- info('mica | mid, low')           # no mod
a3 <- info('mica | mid-out')            # has mod
a4 <- info('mid-out')                   # has mod
a5 <- info('mid, low')                  # no mod







a1 <- search_names('mica | mid-out, low')       # has mod
a2 <- search_names('mica | mid, low')           # no mod
a3 <- search_names('mica | mid-out')            # has mod
a4 <- search_names('mid-out')                   # has mod
a5 <- search_names('mid, low')                  # no mod

print('has mod')
c(depth(a1), depth(a3), depth(a4))

print('no mod')
c(depth(a2), depth(a5))




find_orthos('oth', 'mica | mid-out, low')
find_orthos('oth', 'mica | mid, low')
find_orthos('oth', 'mica | mid-out')
find_orthos('oth', 'mid-out')
find_orthos('oth', 'mid, low')

find_orthos('oth', 'mid-out')
find_orthos('oth', 'mica | low, mid')
find_orthos('oth', 'mid-in, mid-out, high')
find_orthos('oth', 'mica, swir, p4 | ortho | high | spring:fall | 2019:2022')
find_orthos('oth', 'mica, swir | ortho, dem | low:high | summer | 2019')
