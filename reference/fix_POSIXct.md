# Repair mixed POSIXct/numeric vectors

I don't know how these happen, but they keep showing up. Strings look
like this

    "2025-10-04 01:22:44.55288"  "2025-10-04 01:22:44.55288"  "1767713663.71366"  "1767713663.71366"

## Usage

``` r
fix_POSIXct(x)
```

## Arguments

- x:

  Vector that should all be POSIXct

## Value

Vector that all is POSIXct
