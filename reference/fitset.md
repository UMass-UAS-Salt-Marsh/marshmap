# Set model scores and comments

- Any of

      fitset(rows = <a single row>, score = <fit score>)
      fitset(rows = <a single row>, assess = 'an assessment comment')
      fitset(rows = <a single row>, map = 'a map comment')
      fitset(rows = <a single row>, launch = 'launch comment')

  sets the subjective model fit score, the assessment. comment, or the
  map comment. You can also reset the launch comment, which was set at
  launch. Any of these may be combined in a single call. Note that you
  can use `fitset` on multiple fits, but you'll need to use
  `multiple = TRUE`.

## Usage

``` r
fitset(
  rows,
  score = NULL,
  assess = NULL,
  map = NULL,
  launch = NULL,
  multiple = FALSE
)
```

## Arguments

- rows:

  Selected rows in the fits database. Use one of

  - a vector of `fitids`

  - 'all' for all fits

  - a named list to filter fits. List items are
    `<field in fdb> = <value>`, where `<value>` is a regex for character
    fields, or an actual value (or vector of values) for logical or
    numeric fields.

- score:

  Set the subjective model score in the fits database. This may be
  numeric or character; it'll be treated as a character.

- assess:

  Sets the assessment comment in the fits database

- map:

  Sets the map comment in the fits database

- launch:

  Sets the launch comment in the fits database, replacing the comment
  set at launch

- multiple:

  If TRUE, allows applying to multiple fits
