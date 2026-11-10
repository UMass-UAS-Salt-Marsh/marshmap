#' Gather and prepare GIS data from data sources
#' 
#' Gather raster and vector data from the source (either Google Drive or SFTP), and clip to site 
#' boundary, resample and align to standard resolution. Data will be copied from various source 
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
#' - `field_style` format of the field data (default `old_transects`):
#'   - `old_transects` - one shapefile of buffered polygons per site, named in the `transects`
#'       column of `sites.txt` (deprecated)
#'   - `transects` - one GeoPackage for all sites with raw points, lines, and polygons (legacy
#'       data through 2025). Points and lines are buffered by `field_buffer`; lines are first
#'       shortened by `field_buffer` at each end. Polygons (photo-interpreted water) are used as drawn.
#'   - `plots` - one GeoPackage for all sites with a circular plot for each sample (2026 on).
#'       Points are buffered by `field_buffer`; polygons are used as is.
#' - `transects` for `old_transects`, the directory with field transect shapefiles; for
#'       `transects` and `plots`, the path to the GeoPackage. Relative to `sourcedir`.
#' - `field_buffer` buffer radius in m for field points and lines (default 1). Use 1 for
#'       `transects` and 0.7 for `plots`.
#' - `crs` target projection for all results (default `EPSG:26986`, Mass State Plane, for the
#'       legacy data). Use `EPSG:6491+5703` (NAD83(2011) / Massachusetts Mainland + NAVD88 height)
#'       for the 2026 data. Only the horizontal component is compared, so sources in `EPSG:6491`
#'       aren't reprojected.
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
#' All source data not already in the target projection (`crs` in `pars.yml`) will be reprojected
#' to it.
#'
#' `sites.txt` must include the name of the footprint shapefile for each site and a standard
#' geoTIFF for each site. For `field_style = old_transects`, it must also name the site's field
#' transect shapefile (needed if `field = TRUE`). For the GeoPackage styles, field data are matched
#' to sites by the `site` field in the GeoPackage. The footprint is used for clipping and must be
#' present. The standard must be present if `drone = TRUE` or `field_rasters = TRUE`. It is used
#' as the standard for grain and alignment; all rasters will be resampled to match. Best to use a
#' Mica orthophoto, with ~9 cm resolution.
#' 
#' Note that adding to an existing stack using a different standard will lead to sorrow. **BEST
#' PRACTICE**: don't change the standards in `standards.txt`; if you must change them, clear the 
#' flights/ directory and rerun.
#'
#' If you're reading from the Google Drive or SFTP, you'll need a cache. Best to put this on the 
#' Unity **scratch drive**. Create it with `ws_allocate cache 30` in the Unity shell. You can extend
#' the scratch drive (up to 5 times) with `ws_extend cache 30`. When you're done with it, be polite
#' and release it with `ws_release cache`. You'll need to point to the cache in `~/marshmap.yml`, under 
#' `scratchdir:`.
#'
#' Note that initial runs with Google Drive in a session open the browser for authentication or wait
#' for input from the console, so don't run blindly when using the Google Drive
#' 
#' At the end of a run, the log file will be copied to the flights directory.
#' 
#' Remember that some SFTP servers require connection via VPN
#' 
#' Example runs:
#' 
#'    Complete for all sites:
#' 
#'       `gather('all')`
#'       
#'    Run for one site, June only:
#'    
#'       `gather(site = 'oth', pattern = 'Jun')`
#' 
#'    Run for 2 sites, low tide only:
#' 
#'       `gather(site = c('oth', 'wes'), pattern = '_low_')`
#' 
#' @param site One or more site names, using 3 letter abbreviation. Use `all` to process all sites. 
#'    In batch mode, each named site will be run in a separate job.
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
#' @param drone If TRUE, gather and process drone imagery (geoTIFFs) and run `flights_prep`. If
#'    FALSE, imagery source directories aren't even listed, so a field-only run is quick.
#' @param field If TRUE, download and process the field transects if they don't already exist.
#'    The processed shapefile is saved to the shapefiles directory.
#' @param field_rasters If TRUE, also make rasters from field transects (`transects.tif`) and from
#'    blocks shapefiles, aligned to `standard`. These are only used for random forest models
#'    (`sample`, `fit`); U-Net works directly from the transects shapefile, so default is FALSE.
#' @param ignore_bad_classes If TRUE, don't throw an error if there are classes in the ground
#'    truth shapefile that don't occur in `classes.txt`. Only use this if you're paying careful
#'    attention, because bad classes will crash `do_map` down the line.
#' @param replace_ground_truth If TRUE, replace ground truth data
#' @param replace_caches If TRUE, all cached images (used for `screen`) are replaced
#' @param resources Slurm launch resources. See \link[slurmcollie]{launch}. These take priority
#' #'    over the function's defaults.
#' @param local If TRUE, run locally; otherwise, spawn a batch run on Unity
#' @param trap If TRUE, trap errors in local mode; if FALSE, use normal R error handling. Use this
#'   for debugging. If you get unrecovered errors, the job won't be added to the jobs database. Has
#'   no effect if local = FALSE.
#' @param comment Optional slurmcollie comment
#' @importFrom slurmcollie launch get_resources
#' @export


gather <- function(site, pattern = '', 
                   update = TRUE, check = FALSE, drone = TRUE, field = TRUE,
                   field_rasters = FALSE, ignore_bad_classes = FALSE,
                   replace_ground_truth = FALSE, replace_caches = FALSE, 
                   resources = NULL, local = FALSE, trap = TRUE, comment = NULL) {
   
   
   if(!check)                                         # make sure scratch directory exists if we're going to use it
      if(!dir.exists(the$scratchdir))
         stop('Scratch directory ', the$scratchdir, ' doesn\'t exist. See help(gather).')
   
   
   site <- get_sites(site)$site
   
   resources <- get_resources(resources, list(
      ncpus = 1,                                      # in run of Red River, used 45% of 2 cores, 66 GB memory, took just over an hour
      memory = 180,                                   # NOR and OTH run blew out at 115 GB; 92 GB for WEL. Blew out OTH in flights_prep at 140 GB
      walltime = '10:00:00'
   ))
   
   if(is.null(comment))
      comment <- paste0('gather ', site)
   
   launch('do_gather', reps = site, repname = 'site', 
          moreargs = list(pattern = pattern, update = update, check = check, drone = drone,
                          field = field, field_rasters = field_rasters,
                          ignore_bad_classes = ignore_bad_classes,
                          replace_ground_truth = replace_ground_truth,
                          replace_caches = replace_caches), 
          finish = 'gather_finish',
          local = local, trap = trap, resources = resources, comment = comment)
}
