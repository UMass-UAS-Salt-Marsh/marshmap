# Sample orthoimages for field-collected data

Sample images at points where we have field-collected data, creating a
data table for modeling.

## Usage

``` r
sample(
  site,
  pattern = "{*}",
  n = NULL,
  p = NULL,
  d = NULL,
  classes = NULL,
  minscore = 0,
  maxmissing = 20,
  reclass = NULL,
  balance = TRUE,
  balance_excl = NULL,
  result = NULL,
  transects = NULL,
  drop_corr = NULL,
  reuse = FALSE,
  resources = NULL,
  local = FALSE,
  trap = TRUE,
  comment = NULL
)
```

## Arguments

- site:

  One or more site names, using 3 letter abbreviation. Use `all` to
  process all sites. In batch mode, each named site will be run in a
  separate job.

- pattern:

  File names, portable names, regex matching either, or search names
  selecting files to sample. See Image naming in
  [README](https://github.com/UMass-UAS-Salt-Marsh/marshmap/blob/main/README.md)
  for details. The default is `{*}`, which will include all variables.

- n:

  Number of total samples to return.

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
  Overrides `balance_exclude` from `sites.txt` if supplied.

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
  `p`, `d`, `balance`, `balance_excl`, or `drop_corr`.

- resources:

  Slurm launch resources. See
  [launch](https://rdrr.io/pkg/slurmcollie/man/launch.html). These take
  priority over the function's defaults.

- local:

  If TRUE, run locally; otherwise, spawn a batch run on Unity

- trap:

  If TRUE, trap errors in local mode; if FALSE, use normal R error
  handling. Use this for debugging. If you get unrecovered errors, the
  job won't be added to the jobs database. Has no effect if local =
  FALSE.

- comment:

  Optional slurmcollie comment

## Details

There are three mutually exclusive sampling strategies (n, p, and d).
You must choose exactly one. `n` samples the total number of points
provided. `p` samples the proportion of total points (after balancing,
if `balance` is selected. `d` samples points with a mean (but not
guaranteed) minimum distance. If `n`, `p`, and `d` are all omitted, the
default is `p = 0.05`, for 5% of the data.

Portable names are used for variable names in the resulting data files.
Dashes from modifications are changed to underscore to avoid causing
trouble.

Results are saved in four files, plus a metadata file:

1.  `<result>_all.txt` - A text version of the full dataset (selected by
    `pattern` but not subsetted by `n`, `p`, `d`, `balance`, or
    `drop_corr`). Readable by any software.

2.  `<result>_all.RDS` - An RDS version of the full dataset; far faster
    to read than a text file in R (1.1 s vs. 14.4 s in one example).

3.  `<result>.txt` - A text version of the final selected and subsetted
    dataset, as a text file.

4.  `<result>.RDS` - An RDS version of the final dataset.

5.  `<result>_vars.txt` - Lists the portable names used for variables in
    the sample alongside the file names on disk. This disambiguates when
    there are duplicate portable names in a flights directory.
