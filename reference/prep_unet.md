# Pre-process data for U-Net

Creates numpy arrays ready for fitting in U-Net. Result files are placed
in `<site>/unet/<model>`.

## Usage

``` r
prep_unet(
  model_name,
  resources = NULL,
  local = FALSE,
  trap = TRUE,
  comment = NULL
)
```

## Arguments

- model_name:

  The model name, which is also the name of a `.yml` parameter file in
  the `pars` directory. This file must contain the following:

  - year: the year to fit

  - orthos: portable names of all orthophotos to include

  - patch: size in pixels

  - depth: number of of downsampling stages

  - classes: vector of target classes

  - holdout: percent of data to hold out for validation

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
