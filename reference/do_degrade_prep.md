# Prepare carved training patches for one fold x radius of the degradation experiment

Per-cell prep worker for
[`degrade()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/degrade.md)
(stage `'prep'`). For one spatial fold (a test/val group pair) and one
plot radius, it builds the input stack and prepared transects via the
shared
[`unet_prep_setup()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/unet_prep_setup.md),
makes the fold's fixed 3-way spatial split, carves the TRAINING
transects to radius-`r` disks around fixed synthetic plot centers
(validation/test stay full extent), extracts patches, and exports numpy
arrays. A radius of `Inf` is the full-transect ANCHOR: training
transects are used uncarved. Centers are computed from the fold's
training extent and are therefore identical across radii and seeds
within a fold.

## Usage

``` r
do_degrade_prep(rep, pgrid, exp, model, train, save_gis = FALSE)
```

## Arguments

- rep:

  Row index into `pgrid` (supplied by slurmcollie).

- pgrid:

  data.frame with `radius`, `test`, `val` columns (the fold x radius
  grid).

- exp:

  Experiment YAML base name in `<pars>/unet/`.

- model:

  Model YAML base name in `<pars>/unet/`.

- train:

  Training YAML base name in `<pars>/unet/`, or NULL.

- save_gis:

  If TRUE, save plot centers, clipped disks, and training polys as
  GeoPackages under `f<test>/r<NNN>/gis/` for inspection.

## Details

Writes patches to
`<unetdir>/<model>/degrade/f<test>/r<NNN>/patches/set1/` (where
`NNN = round(radius * 100)`, or `rfull` for the anchor) plus a
`degrade_meta.rds` marker, and — once per fold — the pinned class
weights `f<test>/class_weights_pinned.json` computed from the fold's
full (uncarved) training transects.
