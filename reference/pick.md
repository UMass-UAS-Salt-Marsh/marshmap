# Pick the best image from a portable name

Given a portable name and flights database, pick the image matching the
portable name with the highest score. Ties are broken by picking the
earliest day in the season. In the unlikely event there is more than one
high-scoring flight in the the first one in the database is arbitrarily
chosen.

## Usage

``` r
pick(portable, db)
```

## Arguments

- portable:

  Portable name to find

- db:

  Flights database

## Value

Row in the database with the chosen image
