# Summary stats for extracted patches

Reports stats separately for train and val masks. Hope to see single
class patches \< 80%.

## Usage

``` r
unet_patch_stats(patch_data)
```

## Arguments

- patch_data:

  Extracted patches from `unet_extract_training_patches`

## Value

List with train_stats and val_stats data frames
