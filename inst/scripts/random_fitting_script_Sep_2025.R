gather('oth')
sample('peg', balance_excl = c(9, 23, 27, 28, 32))
sample('sor', balance_excl = c(10, 11, 12, 14, 23, 32, 33))
sample('wel', balance_excl = c(25))
sample('rr', balance_excl = c(25, 32))


fit('peg')
fit('sor')
fit('wel')
fit('rr')


map(152) # sor
map(151) # peg
map(153) # wel
map(154) # rr

# --- running to here

fit('oth')





map(154, clip = c(-70.03782073, -70.0370949, 41.67023975, 41.67115118))       # Red River
map(166, clip = c(-70.72179818, -70.72164328, 42.18346811, 42.19229167), local = TRUE)      # Peggotty, long skinny clip


#----

fit('peg', maxmissing = 20)  # job 167, fit 178
fit('peg', maxmissing = 10)  # job 168, fit 179
fit('oth', maxmissing = 20)  # job 169, fit 180
fit('oth', maxmissing = 10)  # job 170, fit 181
fit('sor', maxmissing = 20)  # job 171, fit 182
fit('sor', maxmissing = 10)  # job 172, fit 183

map(178, clip = c(-70.72179818, -70.72164328, 42.18346811, 42.19229167), local = TRUE)


map(185) # oth    running
map(182) # sor    TERRIBLE!

map(186) # oth, new one
