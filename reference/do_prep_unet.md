# Pre-process data for U-Net

Creates numpy arrays ready for fitting in U-Net. Result files are placed
in `<site>/unet/<model>`.

## Usage

``` r
do_prep_unet(model, save_gis)
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

  - holdout_col: holdout set to use (uses bypoly). Holdout sets are
    created by `gather`, numbering each poly from 1 to 10, repeating if
    necessary. There are 5 sets to choose from.

  - cv: number of cross-validations. Use 1 for a single model, up to 5
    for five-fold cross-validation. Cross-validations are systematic,
    not random. Since there are only 10 sets in each bypoly, the number
    of cross-validations is limited by the values of val and test.

  - val: validation polys from `holdout_col`. Use NULL to skip
    validation, or a vector of the validation polys for the first
    cross-validation (these will be incremented for subsequent
    validations). For 20% validation holdout, use `val = c(1, 6)`. This
    will use
    ``` bypoly01 %in% c(1,6)`` for the first cross-validation,  ```c(2,
    7)\` for the second, and so on.

  - test: test polys from `holdout_col`, as with `val`.

  - overlap: Proportion overlap of patches

  - upscale: number of cells to upscale (default = 1). Use 3 to upscale
    to 3x3, 5 for 5x5, etc.

  - smooth: number of cells to include in moving window mean (default =
    1). Use 3 to smooth to 3x3, etc.

- save_gis:

  If TRUE, saves GIS data for assessment and debugging
