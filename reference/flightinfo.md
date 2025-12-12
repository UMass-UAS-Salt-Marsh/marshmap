# Summarize orthos at a single site

For each year, for each type + sensor, for each season, for each tide
stage, lists names of orthos (%missing).

## Usage

``` r
flightinfo(site, filter = NULL, derived = FALSE)
```

## Arguments

- site:

  Three letter site code

- filter:

  A named list restricting to particular values, e.g.,
  `filter = list(type = 'DEM', season = c('spring', 'summer'))`

- derived:

  If TRUE, include derived variables
