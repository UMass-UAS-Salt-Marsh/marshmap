# Split patches into train and validation sets spatially

Split patches into train and validation sets spatially

## Usage

``` r
unet_spatial_train_val_split(
  patches,
  transects,
  holdout,
  patch_size,
  cell_width
)
```

## Arguments

- patches:

  List from unet_extract_training_patches

- transects:

  Original sf transects object

- holdout:

  Holdout set to use (uses bypoly, classes 1 and 6). Holdout sets are
  created by `gather` to yield at least 20% of separate polys. There are
  5 sets to choose from.

- patch_size:

  Size of patches in cells

- cell_width:

  Width of cell (m)

## Value

List with train and val patch indices
