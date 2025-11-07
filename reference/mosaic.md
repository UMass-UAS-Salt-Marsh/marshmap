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
mosaic(mapids, resources = NULL, local = FALSE, trap = FALSE, comment = NULL)
```

## Arguments

- mapids:

  Vector of two or more map ids to process, with preferred maps listed
  before less-preferred ones

- resources:

  Slurm launch resources. See
  [launch](https://rdrr.io/pkg/slurmcollie/man/launch.html). These take
  priority over the function's defaults.

- local:

  If TRUE, run locally; otherwise, spawn a batch run on Unity

- trap:

  If TRUE, trap errors in local mode; if FALSE, use normal R error
  handling. Use this for debugging. If you get unrecovered errors, the
  job won't be added to the jobs database. Has no effect if local =
  FALSE.

- comment:

  Optional launch / slurmcollie comment

## Details

A shapefile will be produced with map id, fit id, CCR, and Kappa for
underlying cells.

Maps must all be from the same site.
