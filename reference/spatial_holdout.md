# Number polygons spatially for each subclass to give spatially-reasonable holdout sets

Polygons are numbered from `1:count`, starting at the northwest-most
centroid and taking the closest centroid in turn. Numbering is
stratified by `field`. Results are placed in field `bypoly00` in the
`sf` object.

## Usage

``` r
spatial_holdout(shape, field = "subclass", count = 10)
```

## Arguments

- shape:

  `sf` object

- field:

  Name of field to stratify on; use NULL for no stratification

- count:

  How many groups? You probably want 10.

## Value

The modified `sf` object
