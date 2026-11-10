# Check that each source file exists on the result directory and is up to date

Check that each source file exists on the result directory and is up to
date

## Usage

``` r
check_files(files, gd, sourcedir, resultdir)
```

## Arguments

- files:

  Vector of source files to check (paths as listed by
  [get_dir](https://umass-uas-salt-marsh.github.io/marshmap/reference/get_dir.md))

- gd:

  Source Drive info (optional), named list of

  - `dir` Google directory info, from
    [get_dir](https://umass-uas-salt-marsh.github.io/marshmap/reference/get_dir.md)

  - `sourcedrive` which source drive (`local`, `google`, or `sftp`)

  - `sftp` `list(url, user)`

- sourcedir:

  Origin directory of files (unused; files carry their paths)

- resultdir:

  Target directory of files - see if origin files are here and up to
  date

## Value

A vector corresponding to files, TRUE for those that exist and are up to
date
