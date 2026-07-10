# Subsample sites, train, and evaluate one cell of the site-count experiment

Per-cell worker for
[`degrade_count()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/degrade_count.md).
For one spatial fold (a test/val group pair), one requested site count,
and one seed, it builds the input stack and prepared transects via
[`unet_prep_setup()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/unet_prep_setup.md),
makes the fold's fixed 3-way spatial split, draws a random subset of the
fold's TRAINING transects (resampled per seed, nested within a seed),
places synthetic plots on those transects' centerlines, carves them to
the fixed radius, extracts + exports patches, trains the U-Net,
evaluates on the fold's full-extent test set, and writes one tidy result
row. A count of `Inf` is the all-sites anchor (every training transect).
Single-stage: because the subset depends on the seed, carving is
seed-specific and cannot be shared across cells.

## Usage

``` r
do_degrade_count(
  rep,
  grid,
  exp,
  model,
  train,
  radius = 0.5,
  requirecuda = TRUE,
  pin_weights = FALSE,
  save_gis = FALSE
)
```

## Arguments

- rep:

  Row index into `grid` (supplied by slurmcollie).

- grid:

  data.frame with `count`, `seed`, `test`, `val` columns (fold x count x
  seed).

- exp:

  Experiment YAML base name in `<pars>/unet/`.

- model:

  Model YAML base name in `<pars>/unet/`.

- train:

  Training YAML base name in `<pars>/unet/`, or NULL.

- radius:

  Fixed plot radius (m) applied to every cell.

- requirecuda:

  If TRUE (default), abort if CUDA is unavailable.

- pin_weights:

  If TRUE, train with class weights pinned to the fold's full-transect
  frequency (read/computed from `f<test>/class_weights_pinned.json`).

- save_gis:

  If TRUE, save plot centers, carved disks, and sampled training polys
  as GeoPackages under the cell's `gis/` for inspection.

## Details

Reads/writes under
`<unetdir>/<model>/degrade/f<test>/count/c<NNN|all>/s<seed>/`
(`patches/set1/` for exports, `fit/set1/` for the model) and appends a
per-cell row `.../degrade/countcell_f<test>_c<NNN>_s<seed>.csv`. Each
cell writes its own file to avoid concurrent-write races across the
Slurm array. The fold's pinned class weights
(`f<test>/class_weights_pinned.json`, from the full training transects)
are reused if present and computed atomically if not.
