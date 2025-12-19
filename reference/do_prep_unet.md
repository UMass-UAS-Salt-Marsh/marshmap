# Pre-process data for U-Net

Creates numpy arrays ready for fitting in U-Net. Result files are placed
in `<site>/unet/<model>`.

## Usage

``` r
do_prep_unet(model_name)
```

## Arguments

- model_name:

  The model name, which is also the name of a `.yml` parameter file in
  the `pars` directory. This file must contain the following:

  - year: the year to fit

  - orthos: file names of all orthophotos to include

  - patch: size in pixels

  - depth: number of of downsampling stages

  - classes: vector of target classes

  - holdout: percent of data to hold out for validation
