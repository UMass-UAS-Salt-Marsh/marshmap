# Display information on maps

Display map specification and run statistics.

## Usage

``` r
mapinfo(
  rows = "all",
  cols = "normal",
  sort = "mapid",
  decreasing = FALSE,
  nrows = NA,
  quiet = FALSE,
  purged = FALSE,
  timezone = "America/New_York"
)
```

## Arguments

- rows:

  Selected rows in the maps database. Use one of

  - a vector of `mapids`

  - 'all' for all maps

  - a vector of one or more sites

  - a named list to filter maps. List items are
    `<field in mdb> = <value>`, where `<value>` is a regex for character
    fields, or an actual value (or vector of values) for logical or
    numeric fields.

- cols:

  Selected columns to display. Use one of

  - *brief* (1)

  - *normal* (2)

  - *long* (3)

  - *all* (4)

  - 1, 2, 3, or 4 is a shortcut for the above column sets

  - A vector of column names to include

- sort:

  The name of the column to be used to sort the table

- decreasing:

  If TRUE, sort in descending order

- nrows:

  Number of rows to display in the table. Positive numbers display the
  first *n* rows, and negative numbers display the last *n* rows. Use
  `nrows = NA` to display all rows.

- quiet:

  If TRUE, doesn't print anything, just returns values

- purged:

  If TRUE, display info for the purged database rather than the live one

- timezone:

  Time zone for launch time; use NULL to leave times in native UTC

## Value

The model table, invisibly
