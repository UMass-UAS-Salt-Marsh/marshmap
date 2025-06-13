# salt-marsh-mapping
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
authorization token. This needs to be done only once for each user. 

```
set_up_google_drive()
```