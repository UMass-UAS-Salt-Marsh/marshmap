# Map with a trained U-Net model (worker)

Orchestrates the full mapping pipeline: prep patches, predict with GPU,
assemble into GeoTIFF. Called as a batch job by
[`map()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/map.md)
when the fit method is `'unet'`.

## Usage

``` r
do_unet_map(
  model,
  site,
  fit_result = "fit01",
  result,
  which = "all",
  clip = NULL,
  write_probs = FALSE,
  use_distance_weights = TRUE,
  mapid = NULL,
  fitid = NULL,
  requirecuda = TRUE,
  rep = NULL
)
```

## Arguments

- model:

  The model name (base name of the prep `.yml`)

- site:

  Three letter site code

- fit_result:

  The training result subdirectory (e.g., `'fit01'`)

- result:

  Output filename base (without `.tif`), from
  [`map()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/map.md)

- which:

  Which model(s) to use: `'all'`, `'full'`, or integer 1-5

- clip:

  Optional clip extent

- write_probs:

  If TRUE, write probability layers

- use_distance_weights:

  If TRUE (default), weight patch contributions by distance to the
  nearest patch edge when averaging overlapping predictions. Reduces
  visible tile seams. Set FALSE for uniform averaging.

- mapid:

  Map database id

- fitid:

  Fit database id (for reference / logging)

- requirecuda:

  If TRUE (default), abort immediately if CUDA is not available rather
  than silently falling back to CPU. Set to FALSE only for testing
  without a GPU.

- rep:

  Throwaway argument for slurmcollie
