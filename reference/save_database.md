# Save the specified database

Saves the database in directory `the$dbdir`. Previous versions are
renamed e.g., `fdb_1.RDS`, `fdb_2.RDS`, etc and moved to `backups/`.
Everything in `backups/` is save to purge if you're hurting for disk
space.

## Usage

``` r
save_database(database)
```

## Arguments

- database:

  Name of database (should be `fdb` for the model fit database, or `mdb`
  for the map database)

## Details

For the model fit database, `fdb`, `the$last_fit_id` is written to
`last_fit_id.txt` to track the highest fit id used, as these ids are
*never* reused.
