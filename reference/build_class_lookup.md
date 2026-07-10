# Build a class lookup table by searching across class-code columns

Searches for each given class code across all class-code columns in
`classes.txt` (`subclass`, `ICS_V4`, `ICS_V5`, `ICS_V6`) and returns a
data frame of `value`, `name`, and `color`. This supports integrated
maps that mix levels (e.g., `subclass`-level water codes 21/22 alongside
`ICS_V4`-level vegetation codes 102/104).

## Usage

``` r
build_class_lookup(codes, classes_path, levels = NULL, allowmissing = FALSE)
```

## Arguments

- codes:

  (integer) vector of class codes appearing in the map. Must be in 0-255
  (INT1U range).

- classes_path:

  (character) path to `classes.txt` (tab-separated). Defaults to the
  path returned by `read_pars_table('classes')` when called via the
  standard project workflow; for standalone use, supply explicitly.

- levels:

  (character) optional vector of column names to restrict the search to
  (e.g., `c('subclass', 'ICS_V4')`). If `NULL` (default), all class-code
  columns are searched.

- allowmissing:

  (logical) if `FALSE` (default), missing codes throw an error. If
  `TRUE`, missing codes generate a warning and are dropped from the
  lookup.

## Value

A data frame with columns `value` (integer), `name` (character), and
`color` (character, hex like `'#27408b'`), one row per code, sorted by
`value`.

## Details

For each code, all matching `(name, color)` pairs across columns are
collected. If a unique pair is found, it's used. If multiple distinct
pairs are found, the function errors with the conflicting columns named.
If no match is found, the function errors unless `allowmissing = TRUE`,
in which case the code is dropped from the lookup with a warning.

Rows where the code is 999 or the name is `'xxx'` are treated as
placeholders and ignored during the search.
