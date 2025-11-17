# Create derived variables

Crease derived variables such as NDVI and NDRE, upscaled images, and
canopy height estimates.

## Usage

``` r
derive(
  site,
  pattern1 = "",
  pattern2 = NULL,
  metrics = c("NDVI", "NDWIg", "NDRE"),
  window = 3,
  cache = TRUE,
  resources = NULL,
  local = FALSE,
  trap = TRUE,
  comment = NULL
)
```

## Arguments

- site:

  One or more site names, using 3 letter abbreviation. Use `all` to
  process all sites. In batch mode, each named site will be run in a
  separate job.

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

- resources:

  Slurm launch resources. See
  [launch](https://rdrr.io/pkg/slurmcollie/man/launch.html). These take
  priority \#' over the function's defaults.

- local:

  If TRUE, run locally; otherwise, spawn a batch run on Unity

- trap:

  If TRUE, trap errors in local mode; if FALSE, use normal R error
  handling. Use this for debugging. If you get unrecovered errors, the
  job won't be added to the jobs database. Has no effect if local =
  FALSE.

- comment:

  Optional slurmcollie comment

## Details

This function creates any of a number of univariate and bivariate
metrics derived from raster data, such as NDVI and NDRE. Results are
written as rasters to the `flights` directory, with the metric included
in the name. These metrics will be treated like source layers in
subsequent processing and modeling.

For univariate metrics, supply one or more layer names via `pattern1`.
All metrics will be calculated for each layer specified by `pattern1`.
Results will be named `<layer>__<metric>`.

For bivariate metrics, specify matched pairs of layers with `pattern1`
and `pattern2`. It's best to specify complete names (you can use vectors
for each) so the layers are paired properly. If you're crazy enough to
use regular expressions here, scrutinize the result names carefully.
Results will be named `<layer1>__<layer2>__metric`. At the moment,
`NDWIswir` and `delta` are the only bivariate metrics.

Note that all normalized difference (`NDxx`) metrics require five-band
Mica data.

Note that derived metrics get two underscores in their names, e.g.,
`<layer>__NDVI`. This is used to distinguish primary from derived data.

This fits in the workflow after `gather` and before `sample`.
