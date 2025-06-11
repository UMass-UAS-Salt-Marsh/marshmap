#' Collect raster data for each site
#' 
#' Clip to site boundary, resample and align to standard resolution. Data will be copied from various source 
#' locations (orthophotos, DEMs, canopy height models). Robust to crashes and interruptions: cached 
#' datasets that are fully downloaded will be used over re-downloading, and processed rasters won't be 
#' re-processed unless `update = TRUE` or `replace = TRUE`.
#' 
#' Additional parameters, set in the `gather` block in `pars.yml` (see [init()]):
#' 
#' - `sourcedrive` one of `local`, `google`, `sftp`
#'   - `local` - read source from local drive 
#'   - `google` - get source data from currently connected Google Drive (login via browser on first connection) 
#'       and cache it locally. Must set `cachedir` option. 
#'   - `sftp` - get source data from SFTP site. Must set `sftp` and `cachedir` options. 
#' - `sourcedir` directory with source rasters, generally on Google Drive or SFTP site
#' - `subdirs` subdirectories to search, ending with slash. Default = orthos, DEMs, and canopy height models (okay 
#'      to include empty or nonexistent directories). Use `<site>` in subdirectories that include a site name, e.g., 
#'   `<site> Share/Photogrammetry DEMs`. WARNING: paths on the Google Drive are case-sensitive!
#' - `transects` directory with field transect shapefile
#' - `exclude` list of geoTIFFs to exclude, for whatever reasons. Note that files beginning with `bad` are also
#'      excluded
#' - `sftp` `list(url = <address of site>, user = <credentials>)`. Credentials are either `username:password` or 
#'     `*filename` with `username:password`. Make sure 
#'     to include credential files in `.gitignore` and `.Rbuildignore` so it doesn't end up out in the world! 
#' 
#' Source data: 
#'   - geoTIFFs for each site
#'   - `sites` file, table of site abbreviation, site name, footprint shapefile, raster standard, and transect 
#'     shapefile.
#'
#' Results: 
#'   - flights/geoTIFFs, clipped, resampled, and aligned. ***Make sure you've closed ArcGIS/QGIS projects that 
#'   point to these before running!***
#'   - models/gather_data.log
#' 
#' All source data are expected to be in `EPSG:4326`. Non-conforming rasters will be reprojected.
#' 
#' `sites.txt` must include the name of the footprint shapefile for each site, a field transect
#' shapefile, and a standard geoTIFF for each site. The footprint is used for clipping and must be
#' present. The transect contains ground truth data, and must be present if `field = TRUE`. The
#' standard must be present. It is used as the standard for grain and alignment; all rasters will be
#' resampled to match. Standards MUST be in the standard projection, `EPSG:4326`. Best to use a Mica
#' orthophoto, with 8 cm resolution.
#' 
#' Note that adding to an existing stack using a different standard will lead to sorrow. **BEST
#' PRACTICE**: don't change the standards in `standards.txt`; if you must change them, clear the 
#' flights/ directory and rerun.
#'
#' If you're reading from the Google Drive or SFTP, you'll need a cache. Best to put this on the 
#' Unity **scratch drive**. Create it with `ws_allocate cache 30` in the Unity shell. You can extend
#' the scratch drive (up to 5 times) with `ws_extend cache 30`. When you're done with it, be polite
#' and release it with `ws_release cache`. You'll need to point to the cache in `~/pars.yml`, under 
#' `scratchdir:`.
#'
#' Note that initial runs with Google Drive in a session open the browser for authentication or wait
#' for input from the console, so don't run blindly when using the Google Drive
#' 
#' Remember that some SFTP servers require connection via VPN
#' 
#' **When running on Unity**, request 20 GB. It's been using just under 16 GB, and will fail quietly
#' at the default of 8 GB.
#' 
#' Example runs:
#' 
#'    Complete for all sites:
#' 
#'       `gather()`
#'       
#'    Run for one site, June only:
#'    
#'       `gather(site = 'oth', pattern = 'Jun')`
#' 
#'    Run for 2 sites, low tide only:
#' 
#'       `gather(site = c('oth', 'wes'), pattern = '_low_')`
#' 
#' @param site One or more site names, using 3 letter abbreviation. Default = all sites. If running 
#'    in batch mode, each named site will be run in a separate job, though the default (`site = NULL`)
#'    will run all sites in the same job.
#' @param pattern Regex filtering rasters, case-insensitive. Default = "" (match all). Note: only 
#'        files ending in `.tif` are included in any case.
#' Examples: 
#'   - to match all Mica orthophotos, use `mica_orth`
#'   - to match all Mica files from July, use `Jun.*mica`
#'   - to match Mica files for a series of dates, use `11nov20.*mica|14oct20.*mica`
#' @param update If TRUE, only process new files, assuming existing files are good; otherwise,
#'    process all files and replace existing ones. 
#' @param check If TRUE, just check to see that source directories and files exist, but don't 
#'    cache or process anything
#' @param field If TRUE, download and process the field transects if they don't already exist. 
#'    The shapefile is downloaded for reference, and a raster corresponding to `standard` is created.
#' @param local If TRUE, run locally; otherwise, spawn a batch run on Unity
#' @param trap If TRUE, trap errors in local mode; if FALSE, use normal R error handling. Use this
#'   for debugging. If you get unrecovered errors, the job won't be added to the jobs database. Has
#'   no effect if local = FALSE.
#' @param comment Optional slurmcollie comment
#' @importFrom slurmcollie launch
#' @export


gather <- function(site = NULL, pattern = '', 
                     update = TRUE, check = FALSE, field = FALSE, local = FALSE, trap = TRUE, comment = NULL) {
   
   
   resources <- list(ncpus = 1,                       # in run of Red River, used 45% of 2 cores, 66 GB memory, took just over an hour
                     memory = 100,
                     walltime = '20:00:00'
   )
   
   if(is.null(comment))
      comment <- paste0('gather ', paste(site, collapse = ', '))
   
   launch('do_gather', reps = site, repname = 'site', moreargs = list(pattern = pattern, update = update, check = check, 
                                       field = field), local = local, trap = trap, resources = resources, comment = comment)
   
   
}
