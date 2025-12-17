# Build input stack for a given portable ortho name

Build input stack for a given portable ortho name

Extract training patches that overlap with transects

## Usage

``` r
unet_build_input_stack(
  input_stack,
  transects,
  patch = 256,
  overlap = 0.5,
  classes = c(3, 4, 5, 6),
  class_mapping = c(`3` = 0, `4` = 1, `5` = 2, `6` = 3)
)

unet_build_input_stack(
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

- portable_name:

  e.g., "ortho_mica_fall_2022_high"

- ortho_dir:

  Directory containing ortho TIFFs

- ortho_lookup:

  Named vector mapping portable names to actual filenames

## Value

SpatRaster with 8 bands (RGB, NIR, RedEdge, NDVI, NDRE, DEM)

List containing patches (array), labels (array), masks (array), metadata
(df)
