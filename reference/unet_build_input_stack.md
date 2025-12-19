# Build input stack for a given portable ortho name

Build input stack for a given portable ortho name

## Usage

``` r
unet_build_input_stack(config)
```

## Arguments

- config:

  Named `config` list, including

  - `config$fpath` Path to flights

  - `config$orthos` Vector of orthophoto names (typically a 5-band Mica,
    NDVI, NDRE, and a matching DEM)

  - `config$type` Vector of ortho type corresponding to `orthos`

  - `config$bands` Number of bands in each ortho

- fpath:

  Path to flights directory

## Value

SpatRaster with all bands (typically Blue, Green, Red, NIR, RedEdge,
NDVI, NDRE, DEM)
