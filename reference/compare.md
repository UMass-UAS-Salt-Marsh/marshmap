# Compare U-Net training runs

Scrapes summary.txt files for the given fit IDs and produces a concise
side-by-side comparison of U-Net models. Hyperparameters common to all
runs are listed once at the top; those that differ are listed per run.

## Usage

``` r
compare(fits, md = FALSE, key = FALSE, common = TRUE)
```

## Arguments

- fits:

  Vector of fit IDs to compare

- md:

  If TRUE, emit Markdown with bold formatting on key lines. Default
  FALSE.

- key:

  If TRUE, prepend a legend explaining the output format. Default FALSE.

- common:

  If TRUE, display common parameters. Default TRUE.

## Value

Invisible character vector of the output lines
