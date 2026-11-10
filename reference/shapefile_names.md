# Make field names safe for shapefiles

Shapefiles allow at most 10 characters in field names. If any are
longer, `st_write` abbreviates *all* names, mangling ones we rely on
(`subclass` becomes `subclss`). Instead, we truncate only the long ones,
keeping them unique.

## Usage

``` r
shapefile_names(z)
```

## Arguments

- z:

  `sf` object

## Value

`z` with field names of 10 characters or fewer
