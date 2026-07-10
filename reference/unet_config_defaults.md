# Normalize and derive a U-Net model config

Fills in defaults and derives helper fields for a U-Net model config (as
read from a `<model>.yml` in `<pars>/unet/`). Shared by `do_unet_prep`
and the pixel-degradation experiment (`do_degrade_prep`) so both see an
identical, fully-populated config.

## Usage

``` r
unet_config_defaults(config)
```

## Arguments

- config:

  Config list read from a model `.yml`.

## Value

The enriched config list.

## Details

Derives `fpath`, `bands`, `n_channels`, per-ortho `type`,
`class_mapping`, and `seed`; supplies defaults for `transects`,
`reclass`, `upscale`, `smooth`, `holdout_col`, `cv`, `val`, and `test`;
and validates the cross-validation grid.
