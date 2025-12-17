# Extract training patches that overlap with transects

Extract training patches that overlap with transects

## Usage

``` r
unet_extract_training_patches(
  input_stack,
  transects,
  patch = 256,
  overlap = 0.5,
  classes = c(3, 4, 5, 6),
  class_mapping = c(`3` = 0, `4` = 1, `5` = 2, `6` = 3)
)
```

## Arguments

- input_stack:

  SpatRaster (8 bands)

- transects:

  sf object with ground truth polygons

- patch:

  Size of patches in pixels (e.g., 256)

- overlap:

  Overlap fraction between patches (e.g., 0.5 for 50%)

## Value

List containing patches (array), labels (array), masks (array), metadata
(df)
