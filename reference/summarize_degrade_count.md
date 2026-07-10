# Summarize a site-count degradation experiment

Reads the per-cell rows written by
[`do_degrade_count()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/do_degrade_count.md),
averages over folds and seeds by requested site count, prints a compact
table, and plots overall CCR (and per-class recall) versus the mean
number of training sites on a log x-axis. The all-sites anchor
(`count = Inf`) is drawn as the right-most point and marked with a
vertical guide.

## Usage

``` r
summarize_degrade_count(
  exp = "degrade",
  model = "primary_v6",
  results = NULL,
  train = "train",
  error = c("se", "sd", "none")
)
```

## Arguments

- exp:

  Experiment YAML base name (to locate the results directory).

- model:

  Model YAML base name (to locate the results directory).

- results:

  Optional data.frame of result rows; if NULL, reads `countcell_*.csv`.

- train:

  Training YAML base name (used only to resolve the site/config).

- error:

  Error-bar type drawn on each series: `'se'` (standard error over folds
  x seeds, default), `'sd'`, or `'none'`.

## Value

Invisibly, the aggregated data.frame (per-count means, `_sd`, `_se`,
`n`).
