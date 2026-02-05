# Split transects into train and validation sets

Split transects into train and validation sets

## Usage

``` r
unet_spatial_train_val_split(transects, holdout)
```

## Arguments

- transects:

  Original sf transects object

- holdout:

  Holdout set to use (uses bypoly, classes 1 and 6)

## Value

List with train and val transect ids
