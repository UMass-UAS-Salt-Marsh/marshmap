# Does a spatial object's horizontal CRS match a target CRS?

Compares only the horizontal component, as `authority:code`, so a
compound CRS such as `EPSG:6491+5703` (NAD83(2011) / Massachusetts
Mainland + NAVD88 height) matches `EPSG:6491`. That's what matters for
clipping, resampling, and rasterizing; we never transform vertical
datums here.

## Usage

``` r
crs_matches(x, target)
```

## Arguments

- x:

  An `sf`, `sfc`, `crs`, `SpatRaster`, or `SpatVector` object, or a CRS
  string

- target:

  Target CRS string, e.g., `EPSG:6491+5703` or `EPSG:26986`

## Value

TRUE if the horizontal CRS of `x` matches that of `target`
