#' Collect raster data for each site
#' 
#' Clip to site boundary, resample and align to standard resolution. This is an internal function,
#' called by gather.
#' 
#' ***Hanging issues for SFTP***
#' 
#'   - SFTP implementations behave differently so I'll have to revise once the NAS is up and running.
#'   - Windows dates are a mess for DST. Hopefully Linux won't be.
#'   
#' **When running on Unity**, request 20 GB. It's been using just under 16 GB, and will fail quietly
#' at the default of 8 GB.
#' 
#' @param site site, using 3 letter abbreviation
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
#'    Deal with overlaps in the shapefile--those with more than one subclass will be erased.
#'    The shapefile is downloaded for reference, and a raster corresponding to `standard` is created.
#' @param ignore_bad_classes If TRUE, don't throw an error if there are classes in the ground
#'    truth shapefile that don't occur in `classes.txt`. Only use this if you're paying careful
#'    attention, because bad classes will crash `do_map` down the line.
#' @param replace_caches If TRUE, all cached images (used for `screen`) are replaced
#' @importFrom terra project rast crs writeRaster mask crop resample rasterize vect datatype
#' @importFrom sf st_read st_write
#' @importFrom lubridate as.duration interval
#' @importFrom pkgcond suppress_warnings
#' @importFrom tools file_path_sans_ext
#' @importFrom googledrive drive_auth
#' @export


do_gather <- function(site, pattern = '', 
                      update, check, field, ignore_bad_classes, replace_caches) {
   
   
   start <- Sys.time()
   count <- NULL
   count$tiff <- count$transect <- 0
   
   allsites <- read_pars_table('sites')                                             # site names from abbreviations to paths
   sites <- allsites[match(tolower(site), tolower(allsites$site)), ]
   sites$share <- ifelse(sites$share == '', sites$site_name, sites$share)
   sites$site <- tolower(sites$site)
   
   if(!the$gather$sourcedrive %in% c('local', 'google', 'sftp'))                    # make source sourcedrive is good
      stop('sourcedrive must be one of local, google, or sftp')
   if(any(is.na(sites$site_name)))                                                  # check for missing sites
      stop('Bad site names: ', paste(site[is.na(sites$site_name)], collapse = ', '))
   if(any(t <- is.na(sites$footprint) | sites$footprint == ''))                     # check for missing standards
      stop('Missing footprints for sites ', paste(sites$footprint[t], collapse = ', '))
   if(any(t <- is.na(sites$standard) | sites$standard == ''))                       # check for missing standards
      stop('Missing standards for sites ', paste(sites$site[t], collapse = ', '))
   
   if(!check &                                                                      #    if we're not just checking,
      (the$gather$sourcedrive %in% c('google', 'sftp')) & 
      !dir.exists(the$cachedir))                                                    #    make sure cache directory exists if needed
      dir.create(the$cachedir, recursive = TRUE)
   
   if(the$gather$sourcedrive == 'google')                                           #    authorize Google Drive if need be
      drive_auth(token = readRDS('~/.google_auth/google_drive_token.RDS'))
   
   
   if(check)
      message('check = TRUE, so checking but not processing files')
   
   
   for(i in 1:dim(sites)[1]) {                                                      # for each site,
      message('Site ', sites$site[i])
      dir <- the$gather$sourcedir
      
      s <- c(the$gather$subdirs, dirname(sites$standard[i]))                        #    add path to standard to subdirs in case it's not there already
      s <- gsub('/+', '/', paste0(s, '/'))                                          #    clean up slashes
      s <- unique(s)                                                                #    and drop likely duplicate
      
      x <- NULL
      for(j in resolve_dir(s, sites$site[i]))                                       #    for each subdir (with site name replacement using share name),
         x <- rbind(x, get_dir(file.path(dir, j), 
                               the$gather$sourcedrive,
                               sftp = the$gather$sftp))                             #       get directory
      
      t <- get_dir(file.path(dir, dirname(sites$footprint[i])), 
                   the$gather$sourcedrive, sftp = the$gather$sftp)                  #    Now get directory for footprint shapefile
      x <- rbind(x, t[grep('.shp$|.shx$|.prj$|.dbf$', t$name),])                    #    only want .shp, .shx, and .prj
      
      
      if(field) {                                                                   #    if we're processing field transects,
         tp <- file.path(the$gather$sourcedir, the$gather$transects)
         t <- get_dir(tp, the$gather$sourcedrive, 
                      sftp = the$gather$sftp)                                       #       get transect directory
         x <- rbind(x, t[grep('.shp$|.shx$|.prj$|.dbf$', t$name),])                 #       only want .shp, .shx, .prj, and .dbf
      }
      
      
      gd <- list(dir = x, sourcedrive = the$gather$sourcedrive, 
                 cachedir = the$cachedir, sftp = the$gather$sftp)                   #    info for Google Drive or SFTP
      
      
      files <- x$name[grep('.tif$', tolower(x$name))]                               #    only want files ending in .tif
      files <- files[grep(tolower(pattern), tolower(files))]                        #    match user's pattern - this is our definitive list of geoTIFFs to process for this site
      files <- files[grep('^bad_', tolower(files), invert = TRUE)]                  #    BUT drop files that begin with 'bad_', as they're corrupted
      files <- files[!files %in% the$gather$exclude]                                #    also drop files listed in exclude
      
      
      dups <- table(files)                                                          #    check for duplicates
      dups <- names(dups[dups > 1])
      if(length(dups) > 0) {
         message('Duplicate files in source data for ', site, ':')
         print(dups)
         stop('Unable to process until duplicates are resolved')
      }
      
      
      if(length(files) != 0) {                                                      #    if there are some geoTIFFs to process,
         
         if(update) {                                                               #       if update, don't mess with files that have already been done
            sdir <- file.path(the$gather$sourcedir, sites$site_name[i])
            rdir <- resolve_dir(the$flightsdir, tolower(sites$site[i]))
            files <- files[!check_files(files, gd, sdir, rdir)]                     #          see which files already exist and are up to date
         }
         
         
         if(check) {                                                                #       if check = TRUE, don't download or process anything
            message('   ', files)                                                   #          but do print the source file names
            next
         }
      }
      
      
      dumb_warning <- 'Sum of Photometric type-related color channels'              #    we don't want to hear about this!
      suppress_warnings(r <- get_rast(file.path(dir, sites$standard[i]), 
                                      gd), 
                        pattern = dumb_warning, class = 'warning')
      standard <- r$rast
      type <- r$type
      missing <- r$missing
      
      message('   Processing ', length(files), ' geoTIFFs...')
      
      
      
      get_sidecars <- function(path, file, gd) {                                    #    helper function: cache shapefile sidecar files
         for(ext in c('.shx', '.prj', '.dbf'))
            t <- get_file(file.path(path, sub('.shp$', ext, file)), gd) 
      }
      
      if(the$gather$sourcedrive %in% c('google', 'sftp'))                           #----Read footprint: if reading from Google Drive or SFTP,
         get_sidecars(dir, sites$footprint[i], gd)                                  #       load two sidecar files for shapefile into cache
      footprint <- st_read(get_file(file.path(dir, sites$footprint[i]), 
                                    gd), quiet = TRUE)                              #    read footprint shapefile (we always do this 'cuz it's cheap)
      
      sf <- resolve_dir(the$shapefilesdir, tolower(sites$site[i]))
      if(!dir.exists(sf))
         dir.create(sf, recursive = TRUE)
      shps <- list.files(the$cachedir, pattern = tools::file_path_sans_ext(basename(sites$footprint[i])))
      for(f in shps)
         file.copy(file.path(the$cachedir, f), sf, overwrite = TRUE, copy.date = TRUE)
      
      
      if(field) {                                                                   #----if reading field transect shapefile,
         fd <- resolve_dir(the$fielddir, tolower(sites$site[i]))
         if(!dir.exists(fd))                                                        #       create field directory if it doesn't exist
            dir.create(fd, recursive = TRUE)
         
         
         if(sites$transects[i] != '')                                               #       if we have transects for this site,
            if(!check_files(sites$transects[i], gd, tp, sf) ) {                     #          if we don't already have transect results or they're outdated,
               message(' Processing field transect shapefile')
               
               tp <- file.path(the$gather$sourcedir, the$gather$transects)
               
               if(the$gather$sourcedrive %in% c('google', 'sftp'))                  #       if reading from Google Drive or SFTP,
                  get_sidecars(tp, sites$transects[i], gd)                          #       load three sidecar files (include .dbf) for shapefile into cache
               
               tpath <- get_file(file.path(tp, sites$transects[i]), gd)             #       path and name of transects shapefile
               
               
               shp <- st_read(tpath)                                                #       read transects shapefile
               u <- sort(unique(shp$Subclass))
               bad <- u[!u %in% read_pars_table('classes')$subclass]
               if(length(bad) > 0) {
                  if(ignore_bad_classes)
                     message('***** Ground truth shapefile has bad classes ', paste(bad, collapse = ', '))
                  else
                     stop('Ground truth shapefile has bad classes ', paste(bad, collapse = ', '))
               }
               
               
               overlaps <- paste0(file_path_sans_ext(tpath), '_final.shp')
               gt <- overlaps(shp, 'Subclass')                                      #       get the shapefile and process overlaps
               st_write(gt, overlaps, append = FALSE)                               #       save the overlapped shapefile as *_final
               
               suppressWarnings(transects <-                                        #       mask gives a bogus warning that CRS do not match
                                   rasterize(vect(overlaps), standard, 
                                             field = 'Subclass')$Subclass |>        #       convert it to raster and pull SubCl, numeric version of subclass
                                   crop(footprint) |>                               #       crop, mask, and write
                                   mask(footprint) |>
                                   writeRaster(file.path(fd, 'transects.tif'), overwrite = TRUE,
                                               datatype = type, NAflag = missing))
               
               shps <- list.files(the$cachedir, pattern = tools::file_path_sans_ext(basename(sites$transects[i])))
               for(f in shps)
                  file.copy(file.path(the$cachedir, f), sf, overwrite = TRUE, copy.date = TRUE)
               count$transect <- count$transect + 1
            }
      }
      
      
      
      rd <- resolve_dir(the$flightsdir, tolower(sites$site[i]))                     #    prepare result directory
      if(!dir.exists(rd))
         dir.create(rd, recursive = TRUE)
      
      
      count$tiff <- count$tiff + length(files)
      for(j in files) {                                                             #----for each target geoTIFF in site,
         message('      processing ', j)
         
         if(tryCatch({                                                              #    read the raster, skipping bad ones
            suppressWarnings(r <- get_rast(j, gd))
            g <- r$rast
            type <- r$type
            missing <- r$missing
            FALSE
         }, 
         error = function(cond) {
            message('         *** ', cond[[1]])
            message('         *** Skipping missing or corrupted raster ', j)
            TRUE
         }))
         next
         
         
         if(length(grep('SWIR|XT2', j)) == 1)                                       #    if image is SWIR (shortwave infrared),
            g <- g[[1]]                                                             #       it's 3 redundant bands, so just take first one
         
         
         if(paste(crs(g, describe = TRUE)[c('authority', 'code')], collapse = ':') != 'EPSG:4326') {
            message('         !!! Reprojecting ', g)
            g <- project(g, 'epsg:4326')
         }
         else
            terra::crs(g) <- 'EPSG:4326'                                            #    prevent warnings when CRS is but isn't EPSG:4326 (e.g., 20Jun22_OTH_High_SWIR_Ortho.tif)
         
         pkgcond::suppress_warnings({
            resample(g, standard, method = 'bilinear', threads = TRUE) |>
               crop(footprint) |>
               mask(footprint) |>
               writeRaster(file.path(rd, basename(j)), overwrite = TRUE, 
                           datatype = type, NAflag = missing)                       #    save raster
         }, 
         pattern = dumb_warning, class = 'warning')                                 #    resample, crop, mask, and write to result directory
      }
      
      flights_prep(site, replace_caches = replace_caches)                           #    now count missing values and cache images for screen
      
      message('Finished with site ', sites$site[i])
   }
   d <- as.duration(interval(start, Sys.time()))
   message('Run finished. ', count$tiff,' geoTIFFs and ', count$transect, ' transect shapefiles processed in ', round(d), ifelse(count$tiff == 0, '', paste0('; ', round(d / count$tiff), ' per geoTIFF.')))
}

