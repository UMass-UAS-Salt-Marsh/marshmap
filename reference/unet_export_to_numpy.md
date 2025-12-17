# Export prepared data to numpy arrays for Python

Export prepared data to numpy arrays for Python

## Usage

``` r
unet_export_to_numpy(patch_data, split_indices, output_dir, site_name)
```

## Arguments

- patch_data:

  List from unet_extract_training_patches

- split_indices:

  List from unet_spatial_train_val_split

- output_dir:

  Directory to save numpy files

- site_name:

  Name for files (e.g., "site1")
