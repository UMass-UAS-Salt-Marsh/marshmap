# Pull date, year, and season out of salt marsh imagery files

Robust to wildly haphazard file and date formats (e.g., 18Jun2025,
18June25); does a pretty good job of hunting down the date from the
filename. Dates must be in `dmy` format, followed by an underscore. For
file names with two dates, finds the first.

## Usage

``` r
seasons(files)
```

## Arguments

- files:

  Vector of imagery file names

## Value

named list of:

- date:

  vector of dates in `yyyy-mm-dd` format

- year:

  vector of years, 4 digit integers

- season:

  vector of seasons

## Details

File names must include at least a month and year to get a season, so
`xOTH_Aug_CHM_CSF2012_Thin25cm_TriNN8cm.tif` will return an NA for
season. Such errors may be fixed by editing `flights_<site>.txt`.
