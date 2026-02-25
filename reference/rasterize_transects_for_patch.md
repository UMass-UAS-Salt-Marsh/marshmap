# Helper to rasterize transects for one dataset (train/val/test)

Helper to rasterize transects for one dataset (train/val/test)

## Usage

``` r
rasterize_transects_for_patch(transects, patch_ext, template, class_mapping)
```

## Arguments

- transects:

  sf object of transects for this dataset

- patch_ext:

  terra extent for current patch

- template:

  terra raster template

- class_mapping:

  Named vector for class remapping

## Value

List with mask_array, label_array, n_pixels, classes_string (or NULL if
no data)
