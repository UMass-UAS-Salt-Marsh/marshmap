# Recursively apply fill rules to a raster

For each rule, loads the fill map, recursively applies any nested fills
*to the fill map* (so they're scoped to its territory), then merges the
processed fill map into the parent raster wherever the parent has the
rule's code. This scoping prevents a nested fill from accidentally
overwriting cells in the parent that happen to share a code with the
fill map.

## Usage

``` r
apply_fills(r, rules, source_dir, source_id_rast, source_maps, allowmissing)
```

## Arguments

- r:

  (SpatRaster) the current state of the integrated raster

- rules:

  (list) fill rules at this level - each entry has `code`, `map`,
  optionally `fill`

- source_dir:

  (character) directory containing source maps

- source_id_rast:

  (SpatRaster) parallel raster of source IDs

- source_maps:

  (character) vector of source map names, indexed by the values in
  `source_id_rast`

- allowmissing:

  (logical) passed to recursion

## Value

List with `raster`, `source_id`, and `source_maps`
