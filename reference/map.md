# Produce geoTIFF maps of predicted vegetation cover from fitted models

Console command to launch a prediction run, typically as a batch job on
Unity. Dispatches to `do_map` for RF/AdaBoost models or `do_unet_map`
for U-Net models, determined automatically from the fits database.

## Usage

``` r
map(
  fit,
  site = NULL,
  clip = NULL,
  result = NULL,
  which = "all",
  write_probs = FALSE,
  requirecuda = TRUE,
  resources = NULL,
  local = FALSE,
  trap = FALSE,
  comment = NULL
)
```

## Arguments

- fit:

  Fit id in the fits database, fit object, or path to a .RDS with a fit
  object. U-Net models must be specified by fit id.

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

- which:

  For U-Net models: which model(s) to use for prediction. One of `'all'`
  (default, ensemble of all CV folds), `'full'` (full retrained model),
  or an integer CV fold number. Ignored for RF/AdaBoost models.

- write_probs:

  For U-Net models: if TRUE, write per-class probability layers
  alongside the classification. Ignored for RF/AdaBoost models.

- requirecuda:

  If TRUE (default), abort immediately if CUDA is not available rather
  than silently falling back to CPU. Set to FALSE only for testing
  without a GPU.

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

## Details

**Note**: if you're running this in local mode, multiple runs in a row
in the same R session may blow out memory, thanks to R/Python memory
shenanigans. If you run out of memory in this situation, restart R
between runs. This does not apply to batch runs on Unity.
