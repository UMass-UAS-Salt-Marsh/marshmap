# Create derived variables such as NDVI and NDRE

Create derived variables such as NDVI and NDRE

## Usage

``` r
do_derive(
  site,
  pattern1 = "mica",
  pattern2 = NULL,
  metrics = c("NDVI", "NDRE"),
  window = 3,
  cache
)
```

## Arguments

- site:

  One or more site names, using 3 letter abbreviation. If running in
  batch mode, each named site will be run in a separate job.

- pattern1:

  File names, portable names, regex matching either, or search names
  selecting source for derived variables. See Image naming in
  [README](https://github.com/UMass-UAS-Salt-Marsh/marshmap/blob/main/README.md)
  for details. See details.

- pattern2:

  A second pattern or vector of layer names, used for bivariate metrics.
  See details.

- metrics:

  A list of metrics to apply. Univariate metrics include:

  NDVI

  :   Normalized difference vegetation index,
      `(NIR - red) / (NIR + red)`, an index of biomass

  NDWIg

  :   Normalized difference water index (green, commonly known as
      McFeeter's `NDWI`), `(green - NIR) / (green + NIR)`, primarily
      helps distinguish waterbodies

  NDRE

  :   Normalized difference red edge index, `(NIR - RE) / (NIR + RE)`,
      an index of the amount of chlorophyll in a plant

  mean

  :   mean of each band in a window, size defined by `window`

  std

  :   standard deviation of each band in a window, size defined by
      `window`

  NDVImean

  :   mean of NDVI in a window, size defined by `window`

  NDVIstd

  :   standard deviation of NDVI in a window, size defined by `window`

  NDWIswir

  :   Normalized difference water index (SWIR, commonly known as Gao's
      `NDWI`), `(NIR - SWIR) / (NIR + SWIR)`, an index of water content
      in leaves; requires a Mica layer for `pattern1`, and a matched
      SWIR layer for `pattern2`

  delta

  :   The difference between `pattern1` and `pattern2`, may be useful
      for taking a difference between late-season and early-season DEMs
      to represent vegetation canopy height

- window:

  Window size for `mean`, `std`, `NDVImean`, and `NDVIstd`, in cells;
  windows are square, so just specify a single number. Bonus points if
  you remember to make it odd.

- cache:

  If TRUE, cache images for `screen`. If set to FALSE, these flights
  will be blank in `screen`.
