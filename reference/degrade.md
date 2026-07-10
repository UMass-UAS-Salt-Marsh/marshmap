# Run the U-Net pixel-degradation experiment

Launches the pixel-degradation experiment, which measures how U-Net
accuracy responds to field plot size (sampling footprint) at fixed
resolution. Training transects are carved to radius-`r` disks around
fixed synthetic plot centers, while validation and test labels stay at
full extent. Runs in two stages: `prep` carves and exports patches (one
CPU job per radius); `train` fits and evaluates one GPU job per radius x
seed cell. Run `prep` first, then `train` once prep completes. See
`inst/dev/pixel_degradation_experiment.md`.

## Usage

``` r
degrade(
  model = "primary_v6",
  train = "train",
  exp = "degrade",
  stage = c("prep", "train"),
  radii = NULL,
  seeds = NULL,
  resources = NULL,
  local = FALSE,
  trap = TRUE,
  requirecuda = TRUE,
  save_gis = FALSE,
  folds = NULL,
  anchor = NULL,
  pin_weights = NULL,
  comment = NULL
)
```

## Arguments

- model:

  Base name of the model `.yml` in `<pars>/unet/` (e.g. `'primary_v6'`).

- train:

  Base name of the training `.yml` in `<pars>/unet/`, or NULL.

- exp:

  Base name of the experiment `.yml` in `<pars>/unet/` supplying
  `radii`, `seeds`, `spacing_m`, `test_group`, `val_group`.

- stage:

  `'prep'` (carve + export patches, one job per radius) or `'train'`
  (train + evaluate, one job per radius x seed cell).

- radii:

  Optional numeric vector of plot radii (m); overrides the experiment
  YAML.

- seeds:

  Optional integer vector of training seeds; overrides the experiment
  YAML.

- resources:

  Slurm launch resources; see
  [launch](https://rdrr.io/pkg/slurmcollie/man/launch.html). Take
  priority over the stage defaults. `train` requires a GPU.

- local:

  If TRUE, run locally; otherwise spawn batch jobs on Unity.

- trap:

  If TRUE, trap errors in local mode (see
  [`train()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/train.md)).

- requirecuda:

  If TRUE (default), abort if CUDA is unavailable (train stage).

- save_gis:

  If TRUE (prep stage only), write plot centers, clipped disks, and
  training polys as GeoPackages under `f<test>/r<NNN>/gis/` for
  inspection in QGIS.

- folds:

  Optional fold spec overriding `config$folds`: a list of `c(test, val)`
  group pairs (or a data.frame with `test`/`val` columns). Defaults to
  the base config's single `test_group`/`val_group`.

- anchor:

  If TRUE, also run the full-transect (r = Inf) anchor as an endpoint
  ("r = infinity"). Defaults to `config$anchor`.

- pin_weights:

  If TRUE, train every cell with class weights pinned to the fold's
  full-transect frequency, removing radius-dependent loss weighting.
  Defaults to `config$pin_class_weights`.

- comment:

  Optional slurmcollie comment.
