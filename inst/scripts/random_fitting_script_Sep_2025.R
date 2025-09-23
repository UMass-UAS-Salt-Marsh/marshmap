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



fit('peg', exclude_classes = 28, comment = 'PEG fit without bogus class 28')   # job 179, fit 187

fit('peg', exclude_class = 28, comment = 'fewer rejected orthos')                     # fit 193, job 185         # for these, I've only rejected the very worst images
fit('peg', exclude_class = c(28, 27), comment = 'drop 27 unveg bank again')              # fit 194, job 186         # only 1 poly of 27 unvegetated bank; massively overpredicts

map(1001, comment = 'fewer rejected orthos')
map(1002, comment = 'and drop 27 unveg bank')

map(1002, clip = c(-70.72179818, -70.72164328, 42.18346811, 42.19229167), local = TRUE)


fit('peg', exclude_class = c(28, 27), comment = 'drop 27 unveg bank again')              # fit 1003, job 194         # only 1 poly of 27 unvegetated bank; massively overpredicts


map(1003, clip = c(-70.72179818, -70.72164328, 42.18346811, 42.19229167), local = TRUE)   # test: do I get proper result name and attributes?                     ***** this crashes with names mismatch






fit('peg', exclude_class = c(28, 27), comment = 'drop 27 and one more rejected ortho')              # fit 1004, job 196         # only 1 poly of 27 unvegetated bank; massively overpredicts
map(1004)
