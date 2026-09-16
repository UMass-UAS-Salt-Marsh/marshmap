# Shorten a linestring by `d` at each end

Lines of `2 * d` or shorter collapse to their midpoint, as there's
nothing left to shorten.

## Usage

``` r
shorten_line(g, d)
```

## Arguments

- g:

  LINESTRING geometry

- d:

  Distance in m to drop from each end

## Value

Shortened LINESTRING, or a POINT if the line was too short to shorten
