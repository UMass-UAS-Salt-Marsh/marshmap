# Pre-process data for U-Net

Creates numpy arrays ready for fitting in U-Net. Result files are placed
in `<site>/unet/<model>`.

## Usage

``` r
do_prep_unet(model)
```

## Arguments

- model:

  The model name, which is also the name of a `.yml` parameter file in
  the `pars` directory. This file must contain the following:

  - years: the year(s) of field data to fit

  - orthos: file names of all orthophotos to include

  - patch: size in pixels

  - depth: number of of downsampling stages

  - classes: vector of target classes

  - holdout: holdout set to use (uses bypoly, classes 1 and 6). Holdout
    sets are created by `gather` to yield at least 20% of separate
    polys. There are 5 sets to choose from.
