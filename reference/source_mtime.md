# Last modified date of a file on the source drive

Last modified date of a file on the source drive

## Usage

``` r
source_mtime(file, gd)
```

## Arguments

- file:

  Source file path. For `local`, this is the full path; for Google Drive
  and SFTP, the file is looked up by name (case-insensitive) in
  `gd$dir`.

- gd:

  Source drive info; see
  [check_files](https://umass-uas-salt-marsh.github.io/marshmap/reference/check_files.md)

## Value

Last modified date (POSIXct)
