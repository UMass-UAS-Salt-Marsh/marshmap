# Return a file name from the local drive, Google Drive, or SFTP

If reading from the Google Drive or SFTP, the file is cached on the
scratch drive (`gd$cache`), and reused as long as it isn't outdated. Get
`gd$dir` with sister function
[get_dir](https://umass-uas-salt-marsh.github.io/marshmap/reference/get_dir.md).

## Usage

``` r
get_file(name, gd)
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

path to file on local drive

## Details

Notes:

- this code assumes that all files have unique names, even if from
  different directories. This holds true for the UAS salt marsh project,
  so good enough. \*\*\* IF REPURPOSING THIS CODE, beware! \*\*\*

- cached files are reused if they're not outdated. Downloads from Google
  Drive or SFTP to Unity are wicked fast, so don't feel bad freeing up
  the scratch drive after a run. It's the polite thing to do.

- we don't check for a full cache drive, as the Unity scratch drive has
  a 50 TB limit and we have \< 1 TB of data. Again, IF REPURPOSING,
  beware!

- we protect against crashed or interrupted downloads by downloading to
  a temporary file that is renamed after completion.

- when reading from SFTP, the entire file must be able to fit in memory.
  There should be plenty of room for the files in the salt marsh
  project.

- files on the remote drive are treated as case-insensitive
