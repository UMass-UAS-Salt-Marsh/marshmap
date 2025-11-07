# Create a new database

Creates a new empty fits database (`fdb`) or maps database (`mdb`). This
is a drastic function, intended to be used only when initially creating
a database or when an existing database is a hopeless mess. Use with
great care–this function will destroy any existing database and backups.
**This function is drastic and unrecoverable.**

## Usage

``` r
new_db(database, really = FALSE)
```

## Arguments

- database:

  Name of database (`fdb` or `mdb`)

- really:

  If TRUE, creates database, **destroying existing database**
