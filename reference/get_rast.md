# A wrapper for `rast(get_file)` that sets missing values to NA

The image geoTIFFs for the Salt Marsh project don't have `NAflag` set,
leading to trouble downstream. This function reads a raster from the
Google Drive, SFTP, or local drive, and if `NAflag` isn't set, comes up
with an `NAflag` based on the data type of the raster, (most commonly in
our use, 255 for unsigned bytes and 65535 for unsigned 32-bit integers)
and sets these values to NA.

## Usage

``` r
get_rast(name, gd)
```

## Arguments

- name:

  File path and name

- gd:

  Source drive info, named list of

  - `dir` - Google directory info, from
    [get_dir](https://umass-uas-salt-marsh.github.io/marshmap/reference/get_dir.md)

  - `sourcedrive` - which source drive (`local`, `google`, or `sftp`)

  - `sftp` - list(url, user)

  - `cachedir` - local cache directory

## Value

list of:

- rast:

  raster object

- type:

  data type of the object

- missing:

  NA value of the object

## Details

See
[get_file](https://umass-uas-salt-marsh.github.io/marshmap/reference/get_file.md)
for more info.
