# Split patches into train and validation sets spatially

Split patches into train and validation sets spatially

## Usage

``` r
unet_spatial_train_val_split(patch_data, transects, holdout = 0.2, seed = 42)
```

## Arguments

- patch_data:

  List from unet_extract_training_patches

- transects:

  Original sf transects object

- holdout:

  Fraction for validation (e.g., 0.2)

- seed:

  Random seed

## Value

List with train and val patch indices
