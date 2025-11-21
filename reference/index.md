# Package index

## Processing sequence

The primary sequence of preparing data, building models, and making
maps. These functions normally spawn batch jobs on Unity via
[slurmcollie](https://github.com/UMassCDS/slurmcollie) (except for
`screen` which is intrinsically interactive), though you can run locally
with `local = TRUE`.

- [`gather()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/gather.md)
  : Gather and prepare GIS data from data sources
- [`screen()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/screen.md)
  : Visually screen orthoimages via a web app
- [`derive()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/derive.md)
  : Create derived variables
- [`sample()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/sample.md)
  : Sample orthoimages for field-collected data
- [`fit()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/fit.md)
  : Build statistical models of vegetation cover
- [`map()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/map.md)
  : Produce geoTIFF maps of predicted vegetation cover from fitted
  models
- [`mosaic()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/mosaic.md)
  : Combines multiple maps, filling in missing data

## Reporting and management functions

These functions report data and model status.

- [`fitinfo()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/fitinfo.md)
  : Display information on model fits
- [`fitset()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/fitset.md)
  : Set model scores and comments
- [`fitpurge()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/fitpurge.md)
  : Purge selected fits from fits database
- [`mapinfo()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/mapinfo.md)
  : Display information on maps
- [`mappurge()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/mappurge.md)
  : Purge selected maps from maps database
- [`assess()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/assess.md)
  : Assess a model fit from validation data
- [`flights_report()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/flights_report.md)
  : Produce reports on orthoimages for all sites
- [`sample_freq()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/sample_freq.md)
  : Create a frequency table of number of cells by subclass from field
  data
- [`importance()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/importance.md)
  : Produce a summary of variable importance across multiple fits
- [`sampleinfo()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/sampleinfo.md)
  : Give summary of sample data file

## Utility functions

Uncommonly-used utility functions.

- [`init()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/init.md)
  : Initialize marshmap with user parameters
- [`build_flights_db()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/build_flights_db.md)
  : Build or update the flights database
- [`find_orthos()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/find_orthos.md)
  : Find orthophotos for a site
- [`maketiles()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/maketiles.md)
  : Create tiles with numbered blocks
- [`refit()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/refit.md)
  : Relaunches specified fits, purging the old job and fit
- [`upscale_clone()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/upscale_clone.md)
  : Clones a site directory at a new grain
- [`upscale_more()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/upscale_more.md)
  : Adds more metrics to an already existing upscaled clone

## slurmcollie functions

These functions are part of the
[slurmcollie](https://github.com/UMassCDS/slurmcollie) package, used to
manage batch jobs on the Unity cluster.

- [`info()`](https://rdrr.io/pkg/slurmcollie/man/info.html) : Give info
  on batch jobs (from slurmcollie)
- [`showlog()`](https://rdrr.io/pkg/slurmcollie/man/showlog.html) :
  Prints the contents log file for a batch job (from slurmcollie)
- [`kill()`](https://rdrr.io/pkg/slurmcollie/man/kill.html) : Kill
  launched Slurm jobs (from slurmcollie)
- [`purge()`](https://rdrr.io/pkg/slurmcollie/man/purge.html) : Purge
  selected jobs from the jobs database (from slurmcollie)
