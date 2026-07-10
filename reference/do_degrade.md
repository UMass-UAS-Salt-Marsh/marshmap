# Train and evaluate one cell of the pixel-degradation experiment

Per-cell worker for
[`degrade()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/degrade.md)
(stage `'train'`). Trains the U-Net on the carved patches for one fold x
radius (prepared by
[`do_degrade_prep()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/do_degrade_prep.md))
with a given random seed, evaluates on the fold's full-extent test set,
and writes one tidy result row. A radius of `Inf` is the full-transect
anchor.

## Usage

``` r
do_degrade(
  rep,
  grid,
  exp,
  model,
  train,
  requirecuda = TRUE,
  pin_weights = FALSE
)
```

## Arguments

- rep:

  Row index into `grid` (supplied by slurmcollie).

- grid:

  data.frame with `radius`, `seed`, `test`, `val` columns (fold x radius
  x seed).

- exp:

  Experiment YAML base name in `<pars>/unet/`.

- model:

  Model YAML base name in `<pars>/unet/`.

- train:

  Training YAML base name in `<pars>/unet/`, or NULL.

- requirecuda:

  If TRUE (default), abort if CUDA is unavailable.

- pin_weights:

  If TRUE, train with class weights pinned to the fold's full-transect
  frequency (read from `f<test>/class_weights_pinned.json`).

## Details

Reads patches from
`<unetdir>/<model>/degrade/f<test>/r<NNN>/patches/set1/`, writes the fit
to `.../f<test>/r<NNN>/s<seed>/set1/`, and appends a per-cell result
file `.../degrade/cell_f<test>_r<NNN>_s<seed>.csv`. Each cell writes its
own file to avoid concurrent-write races across the Slurm array.
