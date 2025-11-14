# Produce a summary of variable importance across multiple fits

Produce a summary of variable importance across multiple fits

## Usage

``` r
importance(fitids = NULL, vars = NULL, normalize = TRUE)
```

## Arguments

- fitids:

  Vector of fit fitids, or NULL to run for all finished fits

- vars:

  Vector of variables to restrict analysis to. Default = `{*}`, all
  variables. `vars` is processed by `find_orthos`, and may include file
  names, portable names, search names and regular expressions of file
  and portable names. For example, you could use
  `vars = 'summer | low, mid` to look at importances only for summer
  season low and mid tides.

- normalize:

  If TRUE, normalize importance by Kappa, so better fits get more
  importance
