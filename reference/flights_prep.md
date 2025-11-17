# Prepare flights data after `gather`

Run by `gather`, this

1.  Gets percent missing for each ortho (checks for updated orthos from
    missing_filestamp in flights database)

2.  Makes a raster of number of orthos with a missing value in each cell
    (redoes this if any orthos change)

3.  Gets number of bands for each ortho

4.  Caches images for `screen` (checks to see if images are outdated
    with respect to orthos) The flights database is updated accordingly.

## Usage

``` r
flights_prep(site, replace_caches = FALSE, cache = TRUE)
```

## Arguments

- site:

  site, using 3 letter abbreviation

- replace_caches:

  If TRUE, all cached images (used for `screen`) are replaced

- cache:

  If TRUE, cache images for `screen`. If set to FALSE, these flights
  will be blank in `screen`.
