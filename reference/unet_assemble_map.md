# Assemble U-Net map predictions into a georeferenced GeoTIFF

Reads per-patch class probabilities, averages overlapping predictions,
takes argmax, maps back to original class numbers, and writes a GeoTIFF
with a color table matching the project classes.

## Usage

``` r
unet_assemble_map(
  patches_dir,
  output_file,
  config,
  write_probs = FALSE,
  use_distance_weights = TRUE
)
```

## Arguments

- patches_dir:

  Directory with map patches, probabilities, origins, and metadata

- output_file:

  Full path for the output GeoTIFF

- config:

  Config list (from prep yaml, with `classes` and `site`)

- write_probs:

  If TRUE, also write per-class probability layers as a multi-band
  GeoTIFF alongside the classification

- use_distance_weights:

  If TRUE (default), weight pixel contributes by distance to the nearest
  patch edge during averaging. This reduces visible tile artifacts at
  patch boundaries. Set FALSE for uniform averaging (faster, but may
  show seams with low overlap).
