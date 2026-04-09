# Prepare map patches for U-Net prediction (worker)

Tiles the full ortho extent (or a clipped region) into overlapping
patches ready for GPU prediction. Reuses
[`unet_build_input_stack()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/unet_build_input_stack.md)
to ensure identical normalization to training. Saves numpy arrays, a
patch-origin CSV, and a nodata mask for later assembly.

## Usage

``` r
do_unet_prep_map(model, clip = NULL)
```

## Arguments

- model:

  The model name (base name of the prep `.yml`)

- clip:

  Optional clip extent, vector of `xmin`, `xmax`, `ymin`, `ymax`

## Details

Output goes to `<site>/unet/<model>/map_patches/` (or
`map_patches_clip_<n>/` when clipped).
