# Collect raster data for each site

Clip to site boundary, resample and align to standard resolution. This
is an internal function, called by gather.

## Usage

``` r
do_gather(
  site,
  pattern = "",
  update,
  check,
  field,
  ignore_bad_classes,
  replace_caches
)
```

## Arguments

- site:

  site, using 3 letter abbreviation

- pattern:

  Regex filtering rasters, case-insensitive. Default = "" (match all).
  Note: only files ending in `.tif` are included in any case. Examples:

  - to match all Mica orthophotos, use `mica_orth`

  - to match all Mica files from July, use `Jun.*mica`

  - to match Mica files for a series of dates, use
    `11nov20.*mica|14oct20.*mica`

- update:

  If TRUE, only process new files, assuming existing files are good;
  otherwise, process all files and replace existing ones.

- check:

  If TRUE, just check to see that source directories and files exist,
  but don't cache or process anything

- field:

  If TRUE, download and process the field transects if they don't
  already exist. Deal with overlaps in the shapefile–those with more
  than one subclass will be erased. The shapefile is downloaded for
  reference, and a raster corresponding to `standard` is created.

- ignore_bad_classes:

  If TRUE, don't throw an error if there are classes in the ground truth
  shapefile that don't occur in `classes.txt`. Only use this if you're
  paying careful attention, because bad classes will crash `do_map` down
  the line.

- replace_caches:

  If TRUE, all cached images (used for `screen`) are replaced

## Details

***Hanging issues for SFTP***

- SFTP implementations behave differently so I'll have to revise once
  the NAS is up and running.

- Windows dates are a mess for DST. Hopefully Linux won't be.

**When running on Unity**, request 20 GB. It's been using just under 16
GB, and will fail quietly at the default of 8 GB.
