# Prepare map patches for U-Net prediction

Tiles the full ortho extent (or a clipped region) into overlapping
patches for wall-to-wall prediction. Patches are saved as numpy arrays
alongside a CSV of spatial origins for later reassembly.

## Usage

``` r
unet_prep_map(
  fitid = NULL,
  model = NULL,
  clip = NULL,
  resources = NULL,
  local = FALSE,
  trap = TRUE,
  comment = NULL
)
```

## Arguments

- fitid:

  Fit id in the fits database. The model name is resolved from the
  database. Provide either `fitid` or `model`, not both.

- model:

  The model name (base name of the prep `.yml` in `<pars>/unet/`). Use
  this to prep map patches for a model that may have multiple training
  runs, or before any training has been registered in the fits database.

- clip:

  Optional clip extent, vector of `xmin`, `xmax`, `ymin`, `ymax`. If
  NULL, tiles the full ortho extent.

- resources:

  Slurm launch resources. See
  [launch](https://rdrr.io/pkg/slurmcollie/man/launch.html).

- local:

  If TRUE, run locally; otherwise, spawn a batch run on Unity

- trap:

  If TRUE, trap errors in local mode

- comment:

  Optional slurmcollie comment
