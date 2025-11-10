# Create a frequency table of number of cells by subclass from field data

Create a frequency table of number of cells by subclass in field data
geoTIFF for one or more sites. Results are written to the reports
directory as `sample_freq_<site>.txt`.

## Usage

``` r
sample_freq(sites, transects = NULL)
```

## Arguments

- sites:

  One or more site names, using 3 letter abbreviation. Use `all` to
  process all sites.

- transects:

  Name of transects file; default is `transects`.

## Details

Always runs locally. Takes about a minute per site.
