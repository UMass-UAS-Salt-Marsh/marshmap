# Get info for one or more sites

Get info for one or more sites

## Usage

``` r
get_sites(site)
```

## Arguments

- site:

  One or more site names, using 3 letter abbreviation. Use `all` to
  process all sites.

## Value

site Data frame with one or more rows of:

- site:

  Standard 3 letter site abbreviation

- site_name:

  Site name

- share:

  Share name on Google Drive obsolete?

- transects:

  name of ground truth shapefile

- balance_exclude:

  list of classes to exclude from balancing in `sample`
  (comma-separated)

- fit_exclude:

  list of classes to exclude in `fit` (comma-separated)

- footprint:

  path and name to footprint shapefile

- standard:

  path and name of orthophoto standard (use as a variable to include
  site name in path)
