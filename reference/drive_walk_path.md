# Walk down a file path a folder at a time in the currently Google Drive

This is far, far faster than using drive_get or drive_ls with a deep
path on a drive with LOTS of files.

## Usage

``` r
drive_walk_path(path)
```

## Arguments

- path:

  drive path on Google Drive

## Value

A dribble for full path. Returns NULL if the directory does not exist.

## Details

The following takes 6-7 min on our Google Drive, which has ~16,000 files

`drive_ls(path = 'UAS Data Collection/Westport/RFM Processing Inputs/Orthomosaics/')`

while this call takes 6 seconds

`drive_walk_path(path = 'UAS Data Collection/Westport/RFM Processing Inputs/Orthomosaics/')`
