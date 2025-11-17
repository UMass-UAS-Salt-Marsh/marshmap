# Produce a summary of variable importance across multiple fits

Produce a summary of variable importance across multiple fits

## Usage

``` r
importance(
  fitids = NULL,
  vars = NULL,
  result = NULL,
  normalize = TRUE,
  min_ccr = 70
)
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

- result:

  File name to write results to. If NULL, one will be constructed.

- normalize:

  If TRUE, normalize importance by Kappa, so better fits get more
  importance

- min_ccr:

  The minimum CCR to accept (percentage) to keep from polluting
  importance with bad fits
