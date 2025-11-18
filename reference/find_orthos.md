# Find orthophotos for a site

Finds orthophotos at a given site from complete file names, portable
names, search names, or regular expressions that match file names or
portable names. These may be mixed and matched, separated by `+`. This
function is primarily used internally, but you may use this to test and
refine orthoimage designations.

## Usage

``` r
find_orthos(site, descrip, minscore = 0, maxmissing = 20, screen = TRUE)
```

## Arguments

- site:

  Vector of one or more site names

- descrip:

  Character string with one or more of any of the following, separated
  by `+` (you can also provide a vector of character strings–these will
  be treated the same as a vector with elements separated by `+`)

  file name

  :   a complete file name (`.tif` is optional)

  portable name

  :   a portable name

  regex

  :   a regular expression enclosed in
      [`{}`](https://rdrr.io/r/base/Paren.html), to be applied to both
      file names and portable names. Regular expressions are
      case-insensitive.

  search name

  :   a search string (see `search_names` for details)

- minscore:

  Minimum score for orthos. Files with a minimum score of less than this
  are excluded from results. Default is 0, but rejected orthos are
  always excluded.

- maxmissing:

  Maximum percent missing for orthos. Files with percent missing greater
  than this are excluded.

- screen:

  If TRUE, use `minscore` and `maxmissing` to screen results; ignore
  them if FALSE (this is needed for do_map, as we *always* want to use
  all variables that were included in the model, even if scores have
  changed)

## Value

Data frame with

- row:

  row numbers in `flights<site>.txt`

- file:

  file names

- portable:

  portable names

## Details

Note that portable names will be filtered so there is only one result
for each unique portable name. When there are duplicate portable names
at a site, filtering picks the portable name with the highest score,
breaking ties by picking the earliest day in the season. Filtering is
only applied to exact matches of portable names, not when they're
matched by a regex. File names and search names that give multiple
matches are not filtered.

Use `descrip = '{*}'` to match all names.

You may pass more than one site name, in which case all sites will be
searched. In this case, the returned portable names will be the only
useful result.
