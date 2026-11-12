# Find a vector file, preferring GeoPackage over shapefile

Internal vector files (footprints, transects, blocks) are written as
GeoPackages, but older runs and hand-made files may be shapefiles. This
returns `<dir>/<base>.gpkg` if it exists, otherwise `<dir>/<base>.shp`.

## Usage

``` r
vector_file(dir, base, must_exist = TRUE)
```

## Arguments

- dir:

  Directory

- base:

  File name without extension, e.g., `NOR_transects`

- must_exist:

  If TRUE, throw an error if neither exists; if FALSE, return the
  `.gpkg` path (the one we'd write)

## Value

Path to the vector file
