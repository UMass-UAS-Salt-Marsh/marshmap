# Read field data for one site in any of the supported field styles

Reads field data (ground truth) from a local file (already fetched from
the source drive) and returns polygons for the site, ready for
[do_gather](https://umass-uas-salt-marsh.github.io/marshmap/reference/do_gather.md)
to process. The result has no Z values, lowercase field names (with
anything that's not a letter, digit, or underscore turned into
underscores), numeric `subclass`, and numeric `year`. It's left in the
source projection; `do_gather` reprojects if need be.

## Usage

``` r
read_field(path, style, site, buffer)
```

## Arguments

- path:

  Path to local field data file

- style:

  Field style, one of `old_transects`, `transects`, or `plots`

- site:

  Site abbreviation, matched case-insensitively to the `site` field for
  the all-sites styles

- buffer:

  Buffer radius (m) for points and lines. Typically 1 m for `transects`
  and 0.7 m for `plots`.

## Value

`sf` object of field polygons for the site

## Details

Field styles:

- `old_transects` One shapefile per site of already-buffered polygons
  (deprecated). `path` is the site's shapefile. Missing years are filled
  from `targetyear` if present, and any left missing are set to 0.

- `transects` One GeoPackage for all sites, with raw field geometry in
  three layers (`shapes_points`, `shapes_lines`, `shapes_polygons`).
  Points and lines are buffered here; see
  [buffer_field_shapes](https://umass-uas-salt-marsh.github.io/marshmap/reference/buffer_field_shapes.md).
  Polygons (photo-interpreted water features) are used as drawn.

- `plots` One GeoPackage for all sites with a plot for each sample (2026
  on). Points are buffered by `buffer` to give circular plots; polygons
  (e.g., `circles.gpkg` from `marshfield::get_plots`) are used as is.
  Year is taken from `date`.
