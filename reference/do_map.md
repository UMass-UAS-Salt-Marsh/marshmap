# Produce geoTIFF maps of predicted vegetation cover from fitted models

Console command to launch a prediction run via `do_map`, typically in a
batch job on Unity.

## Usage

``` r
do_map(site, fitid, fitfile, clip, result, mapid, rep = NULL)
```

## Arguments

- site:

  Three letter site code. If fitting from a fit id that was built on a
  single site, you may omit `site` to map the same site (this is the
  most common situation). If you want to map sites other than the site
  the model was built on, or the model was built on multiple sites,
  `site` is required.

- fitid:

  id in the fits database (NULL if not specified)

- fitfile:

  Full specification of an RDS file with the fit object

- clip:

  Optional clip, vector of `xmin`, `xmax`, `ymin`, `ymax`

- result:

  Result file name

- mapid:

  Id in maps database

- rep:

  Throwaway argument to make `slurmcollie` happy

## Details

Side effects:

1.  writes a geoTIFF, `<result>.tif` with, and a run info file

2.  `<runinfo>.RDS`, with the following:

    1.  Time taken for the run (s)

    2.  Maximum memory used (GB)

    3.  Raster size (M pixel)

    4.  R error, or NULL for success

Requires `rasterPrep`. Install it with:
`remotes::install_github('ethanplunkett/rasterPrep')`
