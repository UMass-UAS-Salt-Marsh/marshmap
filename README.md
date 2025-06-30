# salt-marsh-mapping <a href="https://github.com/UMass-UAS-Salt-Marsh/salt-marsh-mapping/"><img src="man/figures/hexsticker.png" align="right" height="139"/></a>

UMass UAS Salt Marsh Project salt marsh land cover mapping

## Installation

```
# install.packages("devtools")
devtools::install_github('UMass-UAS-Salt-Marsh/salt-marsh-mapping')
devtools::install_github('bwcompton/batchtools', ref = 'bwcompton-robust-sbatch')         # while waiting for pull request
devtools::install_github('UMassCDS/slurmcollie')
```

## Authorize Google Drive

If you'll be getting data from the Google Drive with `gather`, you'll need get an 
authorization token. This needs to be done only once for each user. Run the following
from the Unity account you'll be using:

```
set_up_google_drive()
```






## Image naming
UAS images (orthophotos, DEMs, and canopy height models) may be referred to in three different ways:

### File name 

This is the file name assigned during image processing. Filenames usually encode the
image's date, site, tide level, sensor, and type, for instance `19Aug22_OTH_Mid_SWIR_Ortho.tif` or
`14Oct20_OTH_Low_Mica_DEM.tif`. Unfortunately file names are somewhat inconsistent, for instance,
the month may be `Sep` or `Sept`, years may be 2 or 4 digits, and some sensors are referred to by
multiple names. Additionally, some filenames follow a wildly different pattern, such as
`OTH_Aug2022_CHM_NoThin_5cmTriNN_NAD83.tif`, a canopy height model. Files are imported from the
source repositories (either Google Drive or SFTP) with their names unmodified, except that file
names that start with a digit have an `x` prepended, thus `14Oct20_OTH_Low_Mica_DEM.tif` becomes
`x14Oct20_OTH_Low_Mica_DEM.tif`.

When using `derive` to create derived images (for example, `NDVI` or `mean upscaling), derived names
are generated from the base name (or names), with derivation information separated with a douple 
underscore, e.g., `x20Jun22_OTH_Mid_Mica_Ortho__NDVI.tif`. See `derive` for details.

These file names are unsuitable for use in modeling for two primary reasons: they include the site
code, and the exact date of the flight, both of which would break any attempt to build a model on 
one or more sites and apply it to others. The name inconsistencies also make them difficult to use.

### Portable name

Portable names are generated build `build_flights_db` (which is called to update the flights database whenever you run `screen`, so 
if you're visually screening all images in a normal process you won't need to worry about this). Portable
names exclude the site, use seasons instead of an exact date, and force naming consistency. 

Portable names for our examples above are


File name | Portable name
---|---
`19Aug22_OTH_Mid_SWIR_Ortho.tif` | `ortho_swir_summer_2022_mid`
`14Oct20_OTH_Low_Mica_DEM.tif` | `dem_mica_fall_2020_low`
`OTH_Aug2022_CHM_NoThin_5cmTriNN_NAD83.tif` | `chm_summer_2022`
`x20Jun22_OTH_Mid_Mica_Ortho__NDVI.tif` | `ndvi_mica_spring_2022_mid`

Portable names are used for variable names in data files created by `sample`, and they're the names you'll see 
in model assessments. You can find the portable name for each file in `data/<site>/flights/flights_<site>.txt`,
and the portable name is displayed in the `screen` app.

### Generalized name