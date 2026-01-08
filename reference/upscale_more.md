# Adds more metrics to an already existing upscaled clone

- this is experimental

## Usage

``` r
upscale_more(
  site,
  newsite,
  cellsize = 1,
  vars = "{*}",
  minscore = 0,
  maxmissing = 20,
  metrics = "all",
  cache = TRUE,
  resources = NULL,
  local = FALSE,
  trap = TRUE,
  comment = NULL
)
```

## Arguments

- site:

  Site name

- newsite:

  Name for cloned site

- cellsize:

  Cell size for new site (m)

- vars:

  File names, portable names, regex matching either, or search names
  selecting files to upscale. See Image naming in
  [README](https://github.com/UMass-UAS-Salt-Marsh/marshmap/blob/main/README.md)
  for details. The default is `{*}`, which will include all variables.

- minscore:

  Minimum score for orthos. Files with a minimum score of less than this
  are excluded. Default is 0, but rejected orthos are always excluded.

- maxmissing:

  Maximum percent missing in orthos. Files with percent missing greater
  than this are excluded.

- metrics:

  A list of metrics, or 'all' for all metrics. May include any of:

  - 'mean' Mean (may already have been done by `upscale_clone`)

  - `sd` Standard deviation

  - `q05`, `q10`, `q25`, `median`, `q75`, `q90`, and `q95` Quantiles

  - `r0595`, `r1090`, `iqr` Quantile ranges: 5th-95th, 10th-90th, and
    interquartile range

  - `skewness` and `kurtosis`, for Ryan

- cache:

  If TRUE, build cached images for `screen`

- resources:

  Slurm launch resources. See
  [launch](https://rdrr.io/pkg/slurmcollie/man/launch.html). These take
  priority \#' over the function's defaults.

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

**Note**: all metrics *must* be added to pars.yml under category:
derive.
