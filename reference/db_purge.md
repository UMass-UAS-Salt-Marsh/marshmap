# Purge selected fits or maps from database

Called by `fitpurge` or `mappurge` to purge database rows or restore
them, as well as purging or restoring sidecar files.

## Usage

``` r
db_purge(which, db_name, id_name, rows, failed, undo)
```

## Arguments

- which:

  Which database? Either `fit` or `map`

- db_name:

  Either 'fdb' or 'mdb'

- id_name:

  Either `fitid` or `mapid`

- rows:

  Selected rows in the database. Use one of

  - an empty string doesn't purge any rows, but does purge stray fit
    sidecar files

  - a vector of ids to purge those rows

  - a named list to filter rows. List items are
    `<field in database> = <value>`, where `<value>` is a regex for
    character fields, or an actual value (or vector of values) for
    logical or numeric fields.

- failed:

  If TRUE, all rows where `success` is `FALSE` or `NA` are purged. This
  is an alternative to specifying `rows`.

- undo:

  Undo previous purges. There is no time limit on undoing, and it
  doesn't matter whether you've run more fits or maps since a purge. You
  may supply either:

  - `undo = 'last'`, reverses the previous purge call, and the database
    and associated files are restored.

  - a vector of fit ids corresponding to previously purged rows. Note
    that you may view purged fits with `fitinfo` or `mapinfo` with
    `purged = TRUE`.
