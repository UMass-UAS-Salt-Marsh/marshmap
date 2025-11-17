# Sample Y and X variables for a site

Sample imagery for a site and create rectangular data files for model
fitting. This is an internal function, called by sample.

## Usage

``` r
do_sample(
  site,
  vars,
  n,
  p,
  d,
  classes,
  minscore,
  maxmissing,
  reclass,
  balance,
  balance_excl,
  result,
  transects,
  drop_corr,
  reuse
)
```

## Arguments

- site:

  site, using 3 letter abbreviation

- vars:

  File names, portable names, regex matching either, or search names
  selecting files to sample. See Image naming in
  [README](https://github.com/UMass-UAS-Salt-Marsh/marshmap/blob/main/README.md)
  for details.W

- n:

  Number of total samples to return (up to number available).

- p:

  Proportion of total samples to return. Use p = 1 to sample all.

- d:

  Mean distance in cells between samples. No minimum spacing is
  guaranteed.

- classes:

  Class or vector of classes in transects to sample. Default is all
  classes.

- minscore:

  Minimum score for orthos. Files with a minimum score of less than this
  are excluded from results. Default is 0, but rejected orthos are
  always excluded.

- maxmissing:

  Maximum percent missing in orthos. Files with percent missing greater
  than this are excluded.

- reclass:

  Vector of paired classes to reclassify, e.g.,
  `reclass = c(13, 2, 3, 4)` would reclassify all 13s to 2 and 4s to 3,
  lumping each pair of classes.

- balance:

  If TRUE, balance number of samples for each class. Points will be
  randomly selected to match the sparsest class.

- balance_excl:

  Vector of classes to exclude when determining sample size when
  balancing. Include classes with low samples we don't care much about.

- result:

  Name of result file. If not specified, file will be constructed from
  site, number of X vars, and strategy.

- transects:

  Name of transects file; default is `transects`.

- drop_corr:

  Drop one of any pair of variables with correlation more than
  `drop_corr`.

- reuse:

  Reuse the named file (ending in `_all.txt`) from previous run, rather
  than resampling. Saves a whole lot of time if you're changing `n`,
  `p`, `d`, `balance`, `balance_excl`, or `drop_corr`. \*\* Not
  implemented yet! \*\*

## Value

Sampled data table (invisibly)

## Details

**Memory requirements: I've measured up to 28.5 GB.**
