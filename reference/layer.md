# Combine multiple geoTIFF maps into a single integrated layer

Reads a YAML config from `pars/unet/<name>.yml` describing how to layer
a base map with one or more fill maps, validates it, and either runs the
work locally (for small jobs) or dispatches it to Slurm via
`slurmcollie` (for large jobs). The actual work happens in `do_layer`.

## Usage

``` r
layer(name, slurm = NULL, threshold_mpix = 500)
```

## Arguments

- name:

  (character) base name of the YAML config in `pars/unet/`

- slurm:

  (logical or NULL) `NULL` (default) auto-decides; `TRUE` forces Slurm
  dispatch; `FALSE` forces local execution

- threshold_mpix:

  (numeric) megapixel threshold above which Slurm dispatch is preferred
  when `slurm = NULL`. Default 500.

## Value

Invisibly returns the path to the integrated GeoTIFF (when run locally),
or the slurmcollie job id (when dispatched).

## Details

### YAML config format

    source: /path/to/maps                # directory holding all input maps
    result: integrated1                  # output filename stem (no extension)
    base: map_NOR_1684_all               # base map filename stem
    fill:                                # optional list of fill rules
      - code: 99                         # cells in base with this code...
        map: map_NOR_1701_all            # ...are replaced with this map
        fill:                            # nested fills (arbitrary depth)
          - code: 103
            map: map_NOR_1725_all
          - code: 104
            map: map_NOR_9999_all
      - code: 98
        map: map_NOR_9998_all
    allowmissing: false                  # optional, default false. If true,
                                         #   missing fill codes are warnings,
                                         #   not errors.

### Validation

Before any heavy work, `layer()` checks:

- Config file exists and parses

- Required keys present (source, result, base)

- All referenced map files exist on disk

- All declared fill codes are in the INT1U range (0-255)

- All maps have aligned geometry (extent, resolution, CRS)

- Each fill code is actually present in its parent map (this check
  happens inline during `do_layer`, since it requires reading raster
  values; failure produces a clear error mentioning the offending code
  and map)

Geometry alignment is checked by reading raster *headers* only, not
values, so it's cheap.

### Local vs. Slurm dispatch

If `slurm = NULL` (default), `layer()` estimates the work from total
pixel count across all source maps. Below ~500M pixels, runs locally;
above, dispatches to Slurm. Override with `slurm = TRUE` or
`slurm = FALSE`.
