# Write a vector file as a GeoPackage, replacing any existing file

The whole file is replaced (`delete_dsn = TRUE`), so we never end up
with mixed-layer GeoPackages. If the existing file is locked (generally
because it's open in ArcGIS or QGIS), we pause and ask you to close it
in an interactive session, or throw an error in batch mode.

## Usage

``` r
write_vector(x, path)
```

## Arguments

- x:

  `sf` object

- path:

  Path to `.gpkg`
