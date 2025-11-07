# Produce geoTIFF maps of predicted vegetation cover from fitted models

Console command to launch a prediction run via `do_map`, typically in a
batch job on Unity.

## Usage

``` r
map(
  fit,
  site = NULL,
  clip = NULL,
  result = NULL,
  resources = NULL,
  local = FALSE,
  trap = FALSE,
  comment = NULL
)
```

## Arguments

- fit:

  Fit id in the fits database, fit object, or path to a .RDS with a fit
  object

- site:

  Three letter site code. If fitting from a fit id that was built on a
  single site, you may omit `site` to map the same site (this is the
  most common situation). If you want to map sites other than the site
  the model was built on, or the model was built on multiple sites,
  `site` is required.

- clip:

  Optional clip, vector of `xmin`, `xmax`, `ymin`, `ymax`

- result:

  Optional result name. Default is
  `map_<site>_<fit id>_[clip_<size>_ha]`; if a result name is specified,
  the result will be `map_<result>_<site>_<fit id>_[clip_<size>_ha]`,
  retaining the site and fit id, as omitting these breaks your ability
  to track maps back to the fits they're based on.

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

  Optional launch / slurmcollie comment
