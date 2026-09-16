# Field data for a site from the all-sites GeoPackage of raw field geometry

Buffers points and lines to 2 m wide and counts 8 cm cells by area. See
`fieldinfo`.

## Usage

``` r
field_from_gpkg(file, site, buffer)
```

## Arguments

- file:

  GeoPackage with points, lines, and polygons for all sites

- site:

  Three letter site code

- buffer:

  Buffer radius in m, and the distance lines are shortened at each end

## Value

Data frame with columns `year`, `poly`, `subclass`, and `cells`
