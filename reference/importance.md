# Produce a summary of variable importance across multiple fits

Produce a summary of variable importance across multiple fits

## Usage

``` r
importance(ids = NULL)
```

## Arguments

- ids:

  Vector of fit ids, or NULL to run for all finished fits

- constrain:

  A list of attributes to constrain images, e.g.,
  `contrain = list(season = 'summer', tide = c('low', 'mid'))`. This
  would only include images captured in summer with low or mid-tide.
