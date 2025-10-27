# Salt marsh subclass mapping color picker
# B. Compton, 12 Sep 2025



library(readxl)
x <- read_xlsx('C:/Work/etc/saltmarsh/pars/classes.xlsx')
plot(x$subclass, col = x$subclass_color, pch = 15, cex = 4, xlim = c(0, 100000))
text(1:nrow(x), x$subclass, x$subclass_name, pos = 4, offset = 1.5)
