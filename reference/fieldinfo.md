# Summarize number of field-sampled polys and pixels by class and year

Produces a table for `site` with subclass in the rows and year in the
columns, and the number of 8 cm cells and the number of separate polys
(in parentheses) in each cell, with row and column totals. There are two
sources of field data, selected by `onefile`.

## Usage

``` r
fieldinfo(
  site,
  onefile = TRUE,
  file = "C:/Work/saltmarsh/data/all_EPA_field/shapes_output.gpkg",
  buffer = 1
)
```

## Arguments

- site:

  Three letter site code

- onefile:

  If TRUE, read raw field data for all sites from the GeoPackage `file`;
  if FALSE, use the site's `transects.tif` and transects shapefile

- file:

  GeoPackage with raw field data for all sites, used when
  `onefile = TRUE`

- buffer:

  Buffer radius in m for points and lines, and the distance lines are
  shortened at each end, used when `onefile = TRUE`

## Details

With `onefile = TRUE`, field data for all sites come from a single
GeoPackage (`file`) holding raw field geometry in three layers. As these
data haven't been buffered, we do it here:

- points are buffered by `buffer`, giving 2 m circles;

- lines are shortened by `buffer` at each end and then buffered by
  `buffer`, giving 2 m wide transects with rounded ends that reach the
  ends of the original line. Lines too short to shorten collapse to
  their midpoint, giving a 2 m circle;

- polygons are used as drawn.

Cell counts are then areas divided by the area of an 8 cm cell, so
they're close but not exact: cells aren't actually laid on a grid, and
overlapping polys are counted for each poly they fall in. Note that
years are taken as given, unlike the `onefile = FALSE` case, which falls
back on `targetyear` and uses year 0 for polys with no year at all.

With `onefile = FALSE`, data come from the site's rasterized field
transects (`transects.tif`) and the site's transects shapefile, both
built by `gather`, and cells are counted exactly.
