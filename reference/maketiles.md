# Create tiles with numbered blocks

Create one or more shapefiles corresponding to the named site with tiles
of the specified sizes, numbered in square blocks of 1-9. Used with the
`blocks` option in `fit` to reduce the effects of spatial
autocorrelation.

## Usage

``` r
maketiles(site, sizes)
```

## Arguments

- site:

  Site to align tiles with

- sizes:

  Tile size (m); may be a vector to create several sets of tiles
