# Combine multiple geoTIFF maps into a single integrated map

Worker function for
[`layer()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/layer.md).
Reads a base map and recursively fills specified codes with values from
other maps, producing an integrated classification raster. Each fill
rule replaces all cells with a given code in its parent map with the
corresponding cells from a fill map. Fill rules can nest arbitrarily: a
code in a fill map can itself be filled from yet another map.

## Usage

``` r
do_layer(name, rep = NULL)
```

## Arguments

- name:

  (character) base name of the YAML config in `pars/unet/`. For example,
  `'test1'` reads `pars/unet/test1.yml`.

- rep:

  Throwaway argument to make `slurmcollie` happy.

## Value

Invisibly returns the path to the integrated GeoTIFF.

## Details

Produces:

1.  The integrated map as `<result>.tif` (LZW-compressed, with color
    table and VAT)

2.  A YAML sidecar `<result>_layer.yml` documenting the resolved fill
    tree, the final class legend (code, name, source map), and a
    timestamp
