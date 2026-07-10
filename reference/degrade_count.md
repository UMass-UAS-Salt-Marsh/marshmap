# Run the U-Net site-count degradation experiment

Launches the site-count degradation experiment, which measures how U-Net
accuracy responds to the NUMBER of training sites (transects) at a fixed
plot size. For each spatial fold and site count, a random subset of the
fold's training transects is drawn (resampled per seed), synthetic plots
are placed on their centerlines and carved to a fixed-radius disk, and
the model is trained and evaluated on the fold's full-extent test set.
Single-stage: one GPU job per fold x count x seed cell. Companion to
[`degrade()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/degrade.md)
(the plot-size sweep); see `degrade_count.R`.

## Usage

``` r
degrade_count(
  model = "primary_v6",
  train = "train",
  exp = "degrade",
  counts = NULL,
  seeds = NULL,
  radius = NULL,
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

  Base name of the experiment `.yml` in `<pars>/unet/` supplying `folds`
  (or `test_group`/`val_group`) and `seeds`, and optionally `counts`,
  `count_radius`, `count_anchor`, `pin_class_weights`.

- counts:

  Optional integer vector of training-site counts to sweep; overrides
  `config$counts` (default `c(4, 8, 16, 32, 64)`).

- seeds:

  Optional integer vector of seeds (vary network init, data order, AND
  which sites are drawn); overrides the experiment YAML.

- radius:

  Fixed plot radius (m) applied to every cell; overrides
  `config$count_radius` (default `0.5`).

- resources:

  Slurm launch resources; see
  [launch](https://rdrr.io/pkg/slurmcollie/man/launch.html). Take
  priority over the GPU defaults.

- local:

  If TRUE, run locally; otherwise spawn batch jobs on Unity.

- trap:

  If TRUE, trap errors in local mode (see
  [`train()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/train.md)).

- requirecuda:

  If TRUE (default), abort if CUDA is unavailable.

- save_gis:

  If TRUE, write plot centers, carved disks, and sampled training polys
  as GeoPackages under each cell's `gis/` for inspection in QGIS.

- folds:

  Optional fold spec overriding `config$folds`: a list of `c(test, val)`
  group pairs (or a data.frame with `test`/`val` columns).

- anchor:

  If TRUE, also run the all-sites endpoint (`count = Inf`) as the
  right-hand anchor of the curve. Defaults to `config$count_anchor`,
  else TRUE.

- pin_weights:

  If TRUE (default via `config$pin_class_weights`), train every cell
  with class weights pinned to the fold's full-transect frequency, so
  the loss objective does not shift as sites are dropped.

- comment:

  Optional slurmcollie comment.
