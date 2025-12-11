# Produce reports on orthoimages for all sites

Produce reports on orthoimages, including site summaries, files flagged
for repair, duplicated portable names, and all files for each site

## Usage

``` r
flights_report()
```

## Details

The site report is a series of text files.

1.  Summary of orthos for each site, with stats and frequency tables for
    each site. Unformatted text file, suitable for viewing in a text
    editor.

2.  List of orthos flagged for repair. Tab-delimited text file with
    columns `site`, `name`, `score`, and `comment`. Best viewed in Excel
    or read into R.

3.  List of duplicated portable names. Tab-delimited text file with
    columns `site`, `portable`, `name`, `pick` (`*` for selected
    images), `dups`, `season`, and `score`. Best viewed in Excel or read
    into R.

4.  List of all orthos. Tab-delimited text file with columns `site`,
    `portable`, `name`, `type`, `sensor`, `derive`, `window`, `tide`,
    `tidemod`, `season`, `year`, `score`, and `repair`. Best viewed in
    Excel or read into R.

Files are written to the `reports/` directory.
