# Display information on model fits

Display model specification, assessment, and run statistics.

## Usage

``` r
fitinfo(
  rows = "all",
  cols = "normal",
  report = FALSE,
  sort = "id",
  decreasing = FALSE,
  nrows = NA,
  include_model = FALSE,
  quiet = FALSE,
  purged = FALSE,
  timezone = "America/New_York"
)
```

## Arguments

- rows:

  Selected rows in the fits database. Use one of

  - a vector of `fitids`

  - 'all' for all fits

  - a vector of one or more sites

  - a named list to filter fits. List items are
    `<field in fdb> = <value>`, where `<value>` is a regex for character
    fields, or an actual value (or vector of values) for logical or
    numeric fields.

  - you can supply a negative number as a convenience option to display
    the last *n* rows. This is equivalent to
    `fitinfo(rows = 'all', nrows = -n)`.

- cols:

  Selected columns to display. Use one of

  - *brief* (1)

  - *normal* (2)

  - *long* (3)

  - *all* (4)

  - 1, 2, 3, or 4 is a shortcut for the above column sets

  - A vector of column names to include

  Note that `model`, `full_model`, and `hyper` are normally omitted from
  display, as they tend to be really long and uninformative. If you want
  to see them, include them explicitly in `cols`, or use `cols = 'all'`
  and `include_model = TRUE` to include all three of these.

- report:

  If TRUE, give a report (on a single fit); otherwise, list info on
  fits.

- sort:

  The name of the column to be used to sort the table

- decreasing:

  If TRUE, sort in descending order

- nrows:

  Number of rows to display in the table. Positive numbers display the
  first *n* rows, and negative numbers display the last *n* rows. Use
  `nrows = NA` to display all rows. Note that, as a convenience, you can
  supply a negative number to `rows` to set `nrows`.

- include_model:

  if TRUE, don't explicitly exclude `model`, `full_model`, and `hyper`
  when `cols = 'all'`

- quiet:

  If TRUE, doesn't print anything, just returns values

- purged:

  If TRUE, display info for the purged database rather than the live one

- timezone:

  Time zone for launch time; use NULL to leave times in native UTC

## Value

The fit table or assessment, invisibly

## Details

`fitinfo` works in two different modes:

- `fitinfo(rows = <selected rows>, cols = <selected columns>)` displays
  a table of selected rows and columns

- `fitinfo(rows = ..., report = TRUE)` displays a report for the
  selected fit id, focusing on the model assessment (the same
  information in the `fit` log), also available with `assess(fitid)`
