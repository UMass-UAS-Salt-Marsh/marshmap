# Summary stats for extracted patches

Reports stats separately for train, val, and test masks. Hope to see
single class patches \< 80%.

## Usage

``` r
unet_patch_stats(patch_data)
```

## Arguments

- patch_data:

  Extracted patches from `unet_extract_training_patches`

## Value

List with train_stats, val_stats, and test_stats data frames
