# Build the U-Net input stack and prepared transects

Shared setup for `do_unet_prep` and the pixel-degradation experiment
(`do_degrade_prep`). Builds the multi-band input stack, reads and cleans
the field transects (reclass, class/year filtering, overlap removal,
geometry repair), assigns spatially-distributed holdout groups
(`bypoly00`), and applies optional smoothing and upscaling. Keeping this
in one place guarantees the experiment's train/val/test split is
byte-for-byte identical to the production pipeline's.

## Usage

``` r
unet_prep_setup(config)
```

## Arguments

- config:

  A config list already passed through
  [`unet_config_defaults()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/unet_config_defaults.md).

## Value

List with `input_stack` (SpatRaster) and `transects` (sf, post
`spatial_holdout`, smoothed/upscaled to match the stack).
