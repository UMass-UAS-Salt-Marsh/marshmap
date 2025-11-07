# Load the specified database unless we've already got it

Loads the database from directory `the$dbdir` into environment `the`.

## Usage

``` r
load_database(database, purged = FALSE, lock = TRUE)
```

## Arguments

- database:

  Name of database (should be `fdb` for the model fit database, or `mdb`
  for the map database)

- purged:

  If TRUE, loads the purged version of the database

- lock:

  If TRUE, gets a lock on the database (\*\*\* to be implemented)

## Details

For the model fit database, `fdb`, the file `last_fit_id.txt` is read to
get model sequence for empty databases, as these ids are *never* reused.
If the file isn't found, use the max id from `fdb` or 1000 as a last
resort, and display a warning.
