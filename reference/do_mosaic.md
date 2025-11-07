# Combines multiple maps, filling in missing data

In general, models using more predictors have better performance, but
there's a trade-off, as including predictors with missing data will lead
to missing areas in resulting maps. Mosaic mitigates for this problem by
combining multiple maps. Missing values in the first map are replaced
with values from the second map, missing values in the first two maps
are replaced from the third, and so on. The new composite map will have
data for all cells that any of the source maps have data.

## Usage

``` r
do_mosaic(mapids)
```

## Arguments

- mapids:

  Vector of two or more map ids to process, with preferred maps listed
  before less-preferred ones

## Details

A shapefile will be produced with map id, fit id, CCR, and Kappa for
underlying cells.

Maps must all be from the same site.
