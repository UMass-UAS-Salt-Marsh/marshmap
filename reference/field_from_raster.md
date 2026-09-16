# Field data for a site from its rasterized transects

This is the original approach, counting actual cells in `transects.tif`.
See `fieldinfo`.

## Usage

``` r
field_from_raster(site)
```

## Arguments

- site:

  Three letter site code

## Value

Data frame with columns `year`, `poly`, `subclass`, and `cells`
