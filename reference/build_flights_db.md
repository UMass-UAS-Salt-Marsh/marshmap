# Build or update the flights database

Build or update the flights database for a site, normally called by
`screen`; call if you're unable or unwilling to run `screen`.

## Usage

``` r
build_flights_db(site, refresh = FALSE, really = FALSE)
```

## Arguments

- site:

  Site abbreviation

- refresh:

  Recreated database from scratch. **Warning:** this will destroy your
  existing database, including all assigned scores and comments.
  Requires also supplying `really = TRUE`.

- really:

  If TRUE, allows refresh to recreate the database

## Value

A list of

- db:

  Site database table

- db_name:

  Path and name of database table

## Details

Reads any existing flights\_.txt from flights directory for site, builds
it or updates it for new or deleted files, saves the new version, and
returns the path/name and table. Finds classes from `pars.yml` as
case-insensitive underscore-separated words (after applying name fixes).

Files with changed timestamps are presumed to have been re-downloaded
with gather (as stamps are set in processing). Files shouldn't be
re-downloaded and replaced unless they've changed on the source, so
these files have presumable been repaired. They are refreshed in the
flights database, ready for re-screening.
