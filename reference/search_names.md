# Find orthoimages that match search names

Processes user-friendly generalized orthoimage search names, such as
`mica, swir | ortho | low | summer | 2020:2022`, returning a list of
matching category values from `categories` in `pars.yml`. These
descriptions allow selecting multiple orthoimages clearly and simply
(e.g., `mica | low` selects all low-tide Mica images). Importantly for
cross-site modeling, dates are replaced by seasons.

## Usage

``` r
search_names(descrip)
```

## Arguments

- descrip:

  Description string. See details.

## Value

A named list of all orthophoto attributes designated in the description

## Details

Categories are separated by `|` (spaces are optional anywhere except
within a name). Use commas to separate multiple tags in a category.
Pairs of ordinal categories such as seasons and dates may be provided
separated by a colon to designate a sequence; e.g., `2019:2022` is the
same as `2019, 2020, 2021, 2022`. Tags may include modifiers (for
instance, high tide may be modified as `high.spring`). Modified tags are
returned as lists of paired `category, modifier strings: e.g., `mid.out,
high.spring`results in`list(c('mid', 'out'), c('high', 'spring'))\`.

Non-existent tags generally result in an error with an informative
message. Note that, for multiple tags, the category is determined by the
first tag, so `sprang, summer, fall` will report all three seasons as
errors, even though the second two are correct.

## Examples

``` r
require(saltmarsh)
init()
#> NULL
search_names('mid.in, mid.out, high')
#> Error in read_pars_table("sites"): Parameter sites not in 
search_names('mica, swir, p4 | ortho | high.spring | spring:fall | 2019:2022')
#> Error in read_pars_table("sites"): Parameter sites not in 
search_names('mica, swir | ortho, dem | low:high | spring | 2018')
#> Error in read_pars_table("sites"): Parameter sites not in 
search_names('2022 | oth | mid | mica | ortho | mean.w5')
#> Error in read_pars_table("sites"): Parameter sites not in 
search_names('20x22 | other | muddle | micro')                 # this throws an error
#> Error in read_pars_table("sites"): Parameter sites not in 
```
