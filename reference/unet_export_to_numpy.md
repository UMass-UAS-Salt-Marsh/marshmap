# Export prepared data to numpy arrays for Python

Export prepared data to numpy arrays for Python

## Usage

``` r
unet_export_to_numpy(patches, output_dir, site, class_mapping, set)
```

## Arguments

- patches:

  List from unet_extract_training_patches

- output_dir:

  Directory to save numpy files

- site:

  Name for files (e.g., 'rr')

- class_mapping:

  Named vector mapping original to remapped classes (e.g., c('3'=0,
  '4'=1, '5'=2, '6'=3))

- set:

  Cross-validation set (integer, typically 1:5)
