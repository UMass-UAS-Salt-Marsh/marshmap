# Filter fits database

Filter fits database

## Usage

``` r
filter_db(filter, database)
```

## Arguments

- filter:

  Specify fits with one of:

  - a vector of `ids`

  - 'all' for all fits

  - a named list to filter fits. List items are
    `<field in fits database> = <value>`, where `<value>` is a regex for
    character fields, or an actual value (or vector of values) for
    logical or numeric fields.

- database:

  Name of database, either `fdb` or `mdb`

## Value

A vector of rows numbers in the selected database
