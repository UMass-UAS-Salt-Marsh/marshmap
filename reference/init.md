# Initialize marshmap with user parameters

Reads user-set parameters for package marshmap.

## Usage

``` r
init()
```

## Details

User parameters are set in two distinct locations:

1.  The initialization file, in the user's home directory,
    `~/marshmap.yml`. This file should contain five lines:

    `basedir: c:/Work/etc/marshmap`  
    `parsdir: pars`  
    `parsfile: pars.yml`  
    `scratchdir: c:/Work/etc/marshmap/data/scratch`  

    a\. `basedir` points to the base directory

    b\. `parsdir` is the parameters subdirectory. It should be `pars`
    unless you have a good reason to change it.

    c\. `parsfile` points to the main parameter file. It should be
    `pars.yml`.

    d\. `scratchdir` points to the scratch drive, where the `cache`
    directory will be located. See notes on caching, below.

2.  Everything else, in `<basedir>/<parsdir>`. The primary parameter
    file is `pars.yml`, which points to other parameters (such as
    `sites.txt`).

These parameters include:

- `sites` the name of the sites file, `sites.txt` by default

- `classes` the name of the classes file, `classes.txt` by default

- `dirs` alternative names for various subdirectories. The directories
  will keep the standard structure–you can change names here but not
  paths.

- `gather` a block of parameters for
  [`gather()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/gather.md)

This approach splits the user- and platform-dependent parameters
(`marshmap.yml`) from parameters that are likely to be shared among
users and across platforms (those in `parsdir`). It allows multiple
users on a shared machine (such as Unity cluster) to set user-specific
parameters if need be, while sharing other parameters.

This function reads the user parameters and adds them to the environment
`the` with all parameters. It is automatically run upon loading the
package, and may be rerun by the user if parameter files are changed.

You can change standard directory names (`data`, `models`, `gis`,
`flights`, `field`, `shapefiles`, `samples`, `predicted`, and `cache`)
by setting each within a `dirs:` block in `pars.yml`. Directories
default to standard names, which is usually what you want.

To change parameters on the fly, you can set the components of `the`. If
you change any elements of `dirs`, you'll have to run
[`set_dirs()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/set_dirs.md)
afterwards. Note that parameters changed on the fly will only persist
until the next call to `init()`, which can be called on demand but also
happens automatically when the package is loaded.

For example:

`the$sites <- 'newsites'`  
`the$dirs$cache <- 'newcache'`  
`the$dirs$samples <- 'samples99'`  
[`set_dirs()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/set_dirs.md)

**Notes on caching.** A cache directory is required when
`sourcedrive = google` or `sftp`. The cache directory should be larger
than the total amount of data processed–this code isn't doing any quota
management. This is not an issue when using a [scratch drive on
Unity](https://docs.unity.rc.umass.edu/documentation/managing-files/hpc-workspace/),
as the limit is 50 TB. There's no great need to carry over cached data
over long periods, as downloading from Google or SFTP to Unity is very
fast. Be polite and release the scratch workspace when you're done. See
comments in
[`get_file()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/get_file.md)
for more notes on caching.
