# Summary stats for extracted patches

Hope to see single class patches \< 80%.

## Usage

``` r
unet_patch_stats(patch_data)
```

## Arguments

- patch_data:

  Extracted patches from `unet_extract_training_patches`

## Value

Data frame of stats for each patch (`patch_id`, `n_labeled`,
`n_classes`, `dominant_class`, `purity`)
