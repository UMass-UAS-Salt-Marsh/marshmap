# Split transects into train and validation sets

Split transects into train and validation sets

## Usage

``` r
unet_spatial_train_val_split(transects, holdout_col, cv, val, test)
```

## Arguments

- transects:

  Original sf transects object

- holdout_col:

  Index of holdout set to use, picks from `bypoly01` to `bypoly05`

- cv:

  Number of cross-validations. Use 1 for a single model, up to 5 for
  five-fold

- val:

  Validation polys from `holdout_col`. Use NULL to skip validation, or a
  vector of the validation polys for the first cross-validation (these
  will be incremented for subsequent validations). For 20% validation
  holdout, use `val = c(1, 6)`. This will use
  ``` bypoly01 %in% c(1,6)`` for the first cross-validation,  ```c(2,
  7)\` for the second, and so on.

- test:

  Test polys from `holdout_col`, as with `val`.

## Value

List with train and val transect ids
