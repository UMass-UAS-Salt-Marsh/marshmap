# salt-marsh-mapping <a href="https://github.com/UMass-UAS-Salt-Marsh/salt-marsh-mapping/"><img src="man/figures/hexsticker.png" align="right" height="139"/></a>

UMass UAS Salt Marsh Project salt marsh land cover mapping

`salt-marsh-mapping` is a special-purpose package for the vegetation mapping component of the UMass
UAS Salt Marsh project. This project uses UAS (Unoccupied Aerial Systems), a.k.a "drones," with a
number of sensors, along with field transects to drive vegetation cover models at several salt
marshes in Massachusetts.

This package supports modeling for this project. It is intended to be run on the UMass Unity
cluster using [slurmcollie](https://github.com/UMassCDS/slurmcollie), although all functions may 
be run locally if needed.

This documentation is a work in progress.

## Installation and set up

### Install the package and dependencies

```
# install.packages("devtools")
devtools::install_github('UMass-UAS-Salt-Marsh/salt-marsh-mapping')
devtools::install_github('UMassCDS/slurmcollie')                                    # a companion package required for running batch jobs on Unity
devtools::install_github('bwcompton/batchtools', ref = 'bwcompton-robust-sbatch')   # while waiting for pull request

```

### Authorize Google Drive

If you'll be getting data from the Google Drive with `gather`, you'll need get an 
authorization token. This needs to be done only once for each user. Run the following
from the Unity account you'll be using:

```
set_up_google_drive()
```

## Processing sequence

Here's a brief summary of the processing sequence. See the help for each function for details.
An example sequence will be created soon. All of these are normally launched as batch jobs on Unity 
via `slurmcollie` (except for `screen` which is intrinsically interactive and speedy `assess`).

1. `gather` gather the data from the source (either Google Drive or SFTP)
2. `screen` build the flights database and open a web app to allow visually assigning quality
   scores to each image.
3. `derive` create derived images, such as NDVI (Normalized Difference Vegetation Index), upscaled
   images, and canopy height estimates from the difference between mid-summer and early spring DEMs.
4. `sample` sample images at points where we have field-collected data, creating a data table 
   for modeling.
5. `fit` build statistical models of vegetation cover with random forests, AdaBoost (planned), or
   potentially other modeling frameworks and report model assessment.
6. `assess` provide a model assessment. This is normally included in `fit`, but `assess` may be
   called separately to assess the fit of a model built on one or more sites and applied to other 
   sites.
7. `map` produce geoTIFF maps of predicted vegetation cover. 

### Additional functions

- `build_flights_db` Builds the flights database for a site, necessary after new files are downloaded
   with `gather`. This is normally called by `screen` when you first view a site, so there's no need
   to call it manually unless you are unable or unwilling to run `screen`.
- `flights_report` Creates a report on on orthoimages for all sites, including a summary for each site,
   a list of files flagged for repair in `screen`, a list of duplicated portable names for each site, 
   and a list of all files for each site.
- `find_orthos(site, descrip)` Returns a data frame of file names and portable names matched by one or 
   more file names, portable names, search names, or regular expressions of file names or portable names
   for a given site. You can use this to refine name designations and be sure you're getting what you want.
- `info()` Shows the status of jobs you've launched. This is a `slurmcollie` function.
- `kill(jobs)` Kill one or more jobs you didn't mean to launch (`slurmcollie`).
- `purge(jobs)` Purge jobs that have finished or failed once you no longer care about them (`slurmcollie`).
- `showlog(job)` Shows the log of a running or finished job (`slurmcollie`).

## Image naming

UAS images (orthophotos, DEMs, canopy height models, and derived variables) may be referred to in
three different ways. Functions that take imagery names as arguments (`gather`, `derive`, `sample`, and 
`fit`) use `find_orthos` to resolve all three of these name types, as well as regular expressions of 
file names and portable names. Use `find_orthos` to try out name designations. 

### File name 

This is the file name assigned during image processing. Filenames usually encode the
image's date, site, tide level, sensor, and type, for instance `19Aug22_OTH_Mid_SWIR_Ortho.tif` or
`14Oct20_OTH_Low_Mica_DEM.tif`. File names are somewhat inconsistent, for instance,
the month may be `Sep` or `Sept`, years may be 2 or 4 digits, and some sensors are referred to by
multiple names. Additionally, some filenames follow a wildly different pattern, such as
`OTH_Aug2022_CHM_NoThin_5cmTriNN_NAD83.tif`, a canopy height model. Files are imported from the
source repositories (either Google Drive or SFTP) with their names unmodified, except that file
names that start with a digit have an `x` prepended, thus `14Oct20_OTH_Low_Mica_DEM.tif` becomes
`x14Oct20_OTH_Low_Mica_DEM.tif`. (File names beginning with a digit can lead to 
downstream problems in R, as they are invalid variable names).

When using `derive` to create derived images (for example, `NDVI` or `mean upscaling`), derived names
are generated from the base name (or names), with derivation information separated with a double
underscore, e.g., `x20Jun22_OTH_Mid_Mica_Ortho__NDVI.tif`. See `derive` for details.

These file names are unsuitable for use in modeling because they include the site
code and the exact date of the flight, both of which would break any attempt to build a model on 
one or more sites and apply it to others. The name inconsistencies also make them difficult to use.

### Portable name

Portable names are generated by `build_flights_db` (which is called to update the flights database
whenever you run `screen`, so if you're visually screening all images in a normal process you won't
need to worry about this). Portable names exclude the site, use seasons instead of an exact date,
and force naming consistency.

Portable names for most images consist of:

`<type>_<sensor>_<season>_<year>_<tide>[-tidemod][_<derive>[-<window>]]`

The portable names for canopy height models are simply:

`chm_<source>_<year>`, where `source` is either `lidar` or `delta`.

Here are examples of file names and portable names

File name | Portable name
---|---
`19Aug22_OTH_Mid_SWIR_Ortho.tif` | `ortho_swir_summer_2022_mid`
`14Oct20_OTH_Low_Mica_DEM.tif` | `dem_mica_fall_2020_low`
`OTH_Aug2022_CHM_NoThin_5cmTriNN_NAD83.tif` | `chm_summer_2022`
`x20Jun22_OTH_Mid_Mica_Ortho__NDVI.tif` | `ndvi_mica_spring_2022_mid`
`x01Aug20_OTH_MidOut_Mica_Ortho.tif` | `ortho_mica_summer_2020_mid-out`
`OTH_Aug2022_CHM_NoThin_5cmTriNN_NAD83.tif` | `chm_lidar_2022`
`x26May22_RR_Low_Mica_DEM__x19Aug22_RR_Low_Mica_DEM.tif` | `chm_delta_2022`

Portable names are used for variable names in data files created by `sample`, and they're the names
you'll see in model assessments. You can find the portable name for each file in
`data/<site>/flights/flights_<site>.txt`. The portable name is displayed in the `screen` app.

In cases where portable names refer to two or more image files (because two identical 
site/type/sensor/tide flights were flown in the same season), the image with the highest score will
be used. Remaining ties will be broken by taking the earliest matching image.

### Search name

Finally, search names allow model fits to refer to multiple files in an easily-readable format.
The components of a search name are separated with vertical bars (note these are pretty separators,
NOT logical or--the parts of a search name are conjunctive). Multiple values of a component
are separated with commas, or a colon to select a range for ordinal values such as season or year.
Modifiers (in, out, and spring for tides; window size for upscaled variables) are separated from
the component with a dash, e.g., `mid-out`. Components in a search name may appear in any order. 
Each component in the search name narrows the search, thus `mica | low, mid` matches any files 
with a Mica sensor that are at low or mid-tide.
Here are some example search names:

`mid-in, mid-out, high`  
`mica, swir, p4 | ortho | high-spring | spring:fall | 2019:2022`  
`mica, swir | ortho, dem | low:high | spring | 2018`  

Search names allow model fits to be described clearly and concisely, even for models that contain
dozens of variables, as they often will.

See `help(search_names)` for details.
