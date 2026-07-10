# Summarize a pixel-degradation experiment

Reads the per-cell result rows written by
[`do_degrade()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/do_degrade.md),
averages over folds and seeds, prints a compact table, and plots overall
CCR (and per-class recall) versus plot radius. The full-transect anchor
(radius = Inf) is drawn as a horizontal reference line rather than a
point.

## Usage

``` r
summarize_degrade(
  exp = "degrade",
  model = "primary_v6",
  results = NULL,
  train = "train",
  error = c("se", "sd", "none"),
  pilot = FALSE
)
```

## Arguments

- exp:

  Experiment YAML base name (to locate the results directory).

- model:

  Model YAML base name (to locate the results directory).

- results:

  Optional data.frame of result rows; if NULL, reads the fold-tagged
  `cell_f*.csv` files (falling back to the legacy pilot `cell_r*.csv`).

- train:

  Training YAML base name (used only to resolve the site/config).

- error:

  Error-bar type drawn on each series: `'se'` (standard error of the
  mean over folds x seeds, default), `'sd'` (standard deviation), or
  `'none'`.

- pilot:

  If TRUE, summarize the legacy single-fold pilot (`cell_r*.csv`)
  instead of the fold-tagged runs.

## Value

Invisibly, the aggregated data.frame (per-radius means, `_sd`, `_se`,
`n`).
