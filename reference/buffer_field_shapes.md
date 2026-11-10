# Buffer raw field shapes from the all-sites transects GeoPackage

Reads the three layers of raw field geometry for one site and buffers
them:

## Usage

``` r
buffer_field_shapes(file, site, buffer, polygons = TRUE)
```

## Arguments

- file:

  GeoPackage with layers `shapes_points`, `shapes_lines`, and
  `shapes_polygons`

- site:

  Site abbreviation, matched case-insensitively to the `site` field

- buffer:

  Buffer radius (m) for points and lines, and distance lines are
  shortened at each end

- polygons:

  If TRUE, include polygons; if FALSE, drop them

## Value

`sf` object of buffered field shapes for the site, with cleaned field
names

## Details

- points are buffered by `buffer`, giving circles of radius `buffer`;

- lines are shortened by `buffer` at each end and then buffered by
  `buffer`, giving transects `2 * buffer` wide with rounded ends that
  reach the ends of the original line. Lines too short to shorten
  collapse to their midpoint, giving a circle;

- polygons are used as drawn (if `polygons = TRUE`).

Shared by
[read_field](https://umass-uas-salt-marsh.github.io/marshmap/reference/read_field.md)
(via `gather`) and
[fieldinfo](https://umass-uas-salt-marsh.github.io/marshmap/reference/fieldinfo.md).
