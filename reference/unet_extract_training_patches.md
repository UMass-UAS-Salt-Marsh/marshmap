# Extract training patches with separate train and val masks

Extract training patches with separate train and val masks

## Usage

``` r
unet_extract_training_patches(
  input_stack,
  transects,
  train_ids,
  validate_ids,
  patch = 256,
  overlap = 0.5,
  classes,
  class_mapping
)
```

## Arguments

- input_stack:

  All predictors (raster)

- transects:

  Ground truth polys (sf object)

- train_ids:

  IDs of training transects

- validate_ids:

  IDs of validation transects

- patch:

  Patch size (n pixels)

- overlap:

  Proportional patch overlap (e.g., 0.75 for training, 0 for val)

- classes:

  Classes to include

- class_mapping:

  Mapping from original to 0-indexed classes

## Value

List with patches, labels, train_masks, val_masks, metadata
