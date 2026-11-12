# Read a single-layer vector file (GeoPackage or shapefile)

Throws an error for GeoPackages with more than one layer, rather than
letting `st_read` quietly pick the first.

## Usage

``` r
read_vector(path, ...)
```

## Arguments

- path:

  Path to `.gpkg` or `.shp`

- ...:

  Additional arguments passed to `st_read`

## Value

`sf` object
