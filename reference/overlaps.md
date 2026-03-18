# Erase overlapping polys where class field isn't equal

Erase overlapping polys where class field isn't equal

## Usage

``` r
overlaps(polys, field, all = TRUE)
```

## Arguments

- polys:

  sf object with potential multipolys

- field:

  Field to check for overlaps

- all:

  If TRUE, erase all overlaps, even if fields are equal

## Value

New sf object with overlaps erased unless all values in field are equal
