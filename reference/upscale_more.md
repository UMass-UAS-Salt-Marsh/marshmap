# Adds more metrics to an already existing upscaled clone

- this is experimental

## Usage

``` r
upscale_more(site, newsite, cellsize, metrics = "all", cache = TRUE)
```

## Arguments

- site:

  Site name

- newsite:

  Name for cloned site

- cellsize:

  Cell size for new site (m)

- metrics:

  A list of metrics, or 'all' for all metrics. May include any of:

  - `sd` Standard deviation

  - `q05`, `q10`, `q25`, `median`, `q75`, `q90`, and `q95` Quantiles

  - `r0595`, `r1090`, `iqr` Quantile ranges: 5th-95th, 10th-90th, and
    interquartile range

  - `skewness` and `kurtosis`, for Ryan

- cache:

  If TRUE, build cached images for `screen`
