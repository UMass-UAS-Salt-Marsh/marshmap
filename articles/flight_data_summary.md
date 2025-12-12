# 

/\* Knit with
rmarkdown::render(‘vignettes/articles/flight_data_summary.Rmd’) \*/

#### Flight goals for U-Net

- We want to match good years of field data with a rich set of flights.
  Focus on ortho:mica and DEM at low (or mid) tide, multiple seasons.

## OTH (Old Town Hill)

``` r
flightinfo('oth')
```

#### Notes

- Active management at this site
- Have field data for 2018 and 2021 look reasonably promising (except
  for mowing in the high marsh). 2025 has a decent sample, but is
  inadequate orthos.
- Flights for 2018 are inadequate
- Flights for 2021 look iffy
- Flights for 2025 are inadequate

## PEG (Peggotty Beach)

``` r
flightinfo('peg')
```

#### Notes

## SOR (South River)

``` r
flightinfo('sor')
```

#### Notes

## NOR (North River)

``` r
flightinfo('nor')
```

#### Notes

- We have a crazy amount of field data for 2019, 2023, and 2025 at this
  site

## WEL (Wellfleet Bay)

``` r
flightinfo('wel')
```

#### Notes

- Field data at this site looks great for 2019, and perhaps promising
  for 2025 (though no orthos). Inadequate for 2023.

## RR (Red River)

``` r
flightinfo('rr')
```

#### Notes

- Field data might be enough for 2019.

## ESS (Essex Bay)

``` r
#flightinfo('ess')
```

#### Notes

- Active management at this site
- No field data yet

## BAR (Barnstable)

``` r
flightinfo('bar')
```

#### Notes

- No field data yet

## WES (Westport)

``` r
flightinfo('wes')
```

#### Notes

- No field data yet
