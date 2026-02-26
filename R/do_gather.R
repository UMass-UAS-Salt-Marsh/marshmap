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
#' @param replace_ground_truth If TRUE, replace ground truth data
#' @param replace_caches If TRUE, all cached images (used for `screen`) are replaced
#' @importFrom terra project rast crs writeRaster mask crop resample rasterize vect datatype
#' @importFrom sf st_read st_write st_transform st_zm
#' @importFrom lubridate as.duration interval
#' @importFrom pkgcond suppress_warnings
#' @importFrom tools file_path_sans_ext
#' @importFrom googledrive drive_auth
#' @importFrom utils packageVersion
#' @importFrom stats ave
#' @export


do_gather <- function(site, pattern = '', 
                      update, check, field, ignore_bad_classes, replace_ground_truth, replace_caches) {
   
   
   shuffle <- function(x)                                                           # provide shuffled validation indices stratified by subclasses x
      ave(seq_along(x), x, 
          FUN = function(y) base::sample(rep_len(1:10, length(y))))
   
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
   if(any(t <- is.na(sites$footprint) | sites$footprint == ''))                     # check for missing footprints
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
      
      rd <- resolve_dir(the$flightsdir, tolower(sites$site[i]))                     #    prepare result directory
      if(!dir.exists(rd))
         dir.create(rd, recursive = TRUE)
      
      
      get_sidecars <- function(path, file, gd) {                                    #    helper function: cache shapefile sidecar files
         for(ext in c('.shx', '.prj', '.dbf'))
            t <- get_file(file.path(path, sub('.shp$', ext, file)), gd) 
      }
      
      if(the$gather$sourcedrive %in% c('google', 'sftp'))                           #----Read footprint: if reading from Google Drive or SFTP,
         get_sidecars(dir, sites$footprint[i], gd)                                  #       load two sidecar files for shapefile into cache
      footprint <- st_read(get_file(file.path(dir, sites$footprint[i]), 
                                    gd), promote_to_multi = FALSE, quiet = TRUE)    #    read footprint shapefile (we always do this 'cuz it's cheap)
      footprint <- st_zm(footprint, drop = TRUE)                                    #    we don't want Z values!
      footprint <- st_make_valid(footprint)                                         #    fix any invalid geometries

      if(paste(crs(footprint, describe = TRUE)[c('authority', 'code')], collapse = ':') != 'EPSG:26986') {
         message('         !!! Reprojecting ', basename(sites$footprint[i]), ' to Mass State Plane')
         footprint <- st_transform(footprint, crs = 26986)
         footprint <- st_make_valid(footprint)                                      #    fix any geometries broken by reprojection
      }
      
      sf <- resolve_dir(the$shapefilesdir, tolower(sites$site[i]))
      if(!dir.exists(sf))
         dir.create(sf, recursive = TRUE)
      
      st_write(footprint, 
               file.path(sf, paste0(toupper(sites$site[i]), '_footprint.shp')),
               append = FALSE, quiet = TRUE)                                        #    save reprojected footprint
      
      std <- file.path(rd, basename(sites$standard[i]))                             #    path to stored standard file
      message('   Standard: ', basename(std))
      
      if(!file.exists(std)) {                                                       #    if we don't have the standard in our files yet,
         r <- suppress_warnings(get_rast(
            get_file(file.path(dir, sites$standard[i]), gd)), 
            pattern = dumb_warning, class = 'warning')                              #       get it from the remote drive or the cache
         if(!dir.exists(rd))
            dir.create(rd, recursive = TRUE)
         message('         !!! Reprojecting standard ', basename(std), ' to Mass State Plane')
         suppress_warnings({
            project(r$rast, 'epsg:26986') |>                                        #       reproject it to Mass State Plane
               crop(footprint) |>
               mask(footprint) |>
               writeRaster(std, overwrite = TRUE, 
                           datatype = r$type, NAflag = r$missing)                   #    save raster
         }, 
         pattern = dumb_warning, class = 'warning')                                 #    resample, crop, mask, and write to result directory
      }
      
      r <-get_rast(std)                                                             #    new get the standard
      standard <- r$rast
      type <- r$type
      missing <- r$missing                                                          #    *** these are fucking mess. Need to rethink how I do them--they won't be right for transects or blocks
      
      
      message('   --- Processing ', length(files), ' geoTIFFs ---')
      
      
      shps <- list.files(the$cachedir, pattern = tools::file_path_sans_ext(basename(sites$footprint[i])))
      for(f in shps)
         file.copy(file.path(the$cachedir, f), sf, overwrite = TRUE, copy.date = TRUE)
      
      
      if(field) {                                                                   #----if reading field transect shapefile, ----
         fd <- resolve_dir(the$fielddir, tolower(sites$site[i]))
         if(!dir.exists(fd))                                                        #       create field directory if it doesn't exist
            dir.create(fd, recursive = TRUE)
         
         
         if(sites$transects[i] != '')                                               #       if we have transects for this site,
            if(!check_files(sites$transects[i], gd, tp, sf) | 
               replace_ground_truth) {                                              #          if we don't already have transect results or they're outdated or replace_ground_truth,
               message(' Processing field transect shapefile')
               
               tp <- file.path(the$gather$sourcedir, the$gather$transects)
               
               if(the$gather$sourcedrive %in% c('google', 'sftp'))                  #       if reading from Google Drive or SFTP,
                  get_sidecars(tp, sites$transects[i], gd)                          #       load three sidecar files (include .dbf) for shapefile into cache
               
               tpath <- get_file(file.path(tp, sites$transects[i]), gd)             #       path and name of transects shapefile
               
               
               shp <- st_read(tpath, promote_to_multi = FALSE, quiet = TRUE)        #       read transects shapefile
               shp <- st_zm(shp, drop = TRUE)                                       #       we don't want Z values!
               shp <- st_make_valid(shp)                                            #       fix any invalid geometries
               shp <- shp[st_is_valid(shp), ]                                       #       drop anything that survived invalid
               
               if(paste(crs(shp, describe = TRUE)[c('authority', 'code')], collapse = ':') != 'EPSG:26986') {
                  message('         !!! Reprojecting ', basename(tpath), ' to Mass State Plane')
                  shp <- st_transform(shp, crs = 26986)
                  shp <- st_make_valid(shp)                                         #       fix any geometries broken by reprojection
                  shp <- shp[st_is_valid(shp), ]                                    #       drop anything that survived invalid
               }
               
               names(shp) <- tolower(names(shp))                                    #       we want lowercase names in ground truth shapefile
               
               if(is.character(shp$subclass))                                       #       if subclass is character, turn it into damn numbers!
                  shp$subclass <- as.numeric(shp$subclass)
               
               u <- sort(unique(shp$subclass))
               bad <- u[!u %in% read_pars_table('classes')$subclass]
               if(length(bad) > 0) {
                  if(ignore_bad_classes)
                     message('***** Ground truth shapefile has bad classes ', paste(bad, collapse = ', '))
                  else
                     stop('Ground truth shapefile has bad classes ', paste(bad, collapse = ', '))
               }
               
               shp$poly <- 1:nrow(shp)                                              #       add unique poly ids
               
               shp$year <- as.numeric(shp$year)
               if(!is.null(shp$targetyear))
                  shp$year <- ifelse(is.na(shp$year), shp$targetyear, shp$year)     #       where year is missing, use targetyear - this will fill in for PI
               shp$year[is.na(shp$year)] <- 0                                       #       set NA years to 0
               
               for(j in 1:5)                                                        #       add 5 _bypoly columns
                  shp[[paste0('bypoly', sprintf('%02d', j))]] <- shuffle(shp$subclass)
               
               trpath <- resolve_dir(the$shapefilesdir, tolower(sites$site[i]))
               trname <- paste0(toupper(sites$site[i]), '_transects.shp')
               tr_rejname <- paste0(toupper(sites$site[i]), '_transects_incl_rejects.shp')
               st_write(shp, file.path(trpath, tr_rejname), 
                        append = FALSE, quiet = TRUE)                               #       save the processed transects shapefile with rejected columns intact
               
               if(!is.null(shp$reject))                                             #       if there's a reject column,
                  shp <- shp[is.na(shp$reject) | shp$reject == 0, ]                 #          DROP rejected rows
               
               st_write(shp, file.path(trpath, trname), 
                                       append = FALSE, quiet = TRUE)                #       save the processed transects shapefile 
               
               
               unlapped <- overlaps(shp, 'subclass')                                #       remove overlaps for raster transects (all years) ----
               
               suppress_warnings(transects <-                                       #       mask gives a bogus warning that CRS do not match
                                    rasterize(unlapped, standard, 
                                              field = 'poly')$poly |>               #       convert it to raster populated with unique poly id
                                    crop(footprint) |>                              #       crop, mask, and write
                                    mask(footprint) |>
                                    writeRaster(file.path(fd, 'transects.tif'), overwrite = TRUE,
                                                datatype = type, NAflag = missing))
               
               if(all(is.na(values(transects)))) {
                  message('*** Ground truth data are all missing!!')
                  unlink(file.path(fd, 'transects.tif'))
               }
               
               shps <- list.files(the$cachedir, pattern = tools::file_path_sans_ext(basename(sites$transects[i])))
               # for(f in shps)
               #    file.copy(file.path(the$cachedir, f), sf, overwrite = TRUE, copy.date = TRUE)
               # count$transect <- count$transect + 1
            }
      }
      
      
      bd <- resolve_dir(the$blocksdir, tolower(sites$site[i]))                      #----Read blocks shapefiles from local drive, correct projection assumed ----
      if(dir.exists(bd)) {                                                          #    if the blocks directory exists, have a look
         
         blocks <- file.path(bd, list.files(bd, pattern = '.shp$', 
                                            ignore.case = TRUE))
         for(block in blocks) {                                                     #    for each blocks shapefile, see if raster exists and is up to date,
            s <- file.mtime(block)
            skip <- FALSE
            if(file.exists(gn <- paste0(file_path_sans_ext(block), '.tif')))
               if(s <= file.mtime(gn))
                  skip <- TRUE
            if(!skip) {                                                             #    if not, process it
               message('Processing blocks file ', block, '...')
               suppress_warnings(rasterize(vect(block), standard,                    #       mask gives a bogus warning that CRS do not match
                                           field = 'block')$block |>                 #       convert it to raster
                                    crop(footprint) |>                               #       crop, mask, and write
                                    mask(footprint) |>
                                    writeRaster(gn, overwrite = TRUE,
                                                datatype = type, NAflag = missing))
            }
         }
      }
      
      
      count$tiff <- count$tiff + length(files)
      for(j in files) {                                                             #----for each target geoTIFF in site, ----
         message('      processing ', j)
         
         if(tryCatch({                                                              #    read the raster, skipping bad ones
            r <- 
               suppress_warnings(get_rast(get_file(j, gd)), 
                                 pattern = dumb_warning, class = 'warning')
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
         
         
         if(paste(crs(g, describe = TRUE)[c('authority', 'code')], collapse = ':') != 'EPSG:26986') {
            message('         !!! Reprojecting ', j, ' to Mass State Plane')
            g <- suppress_warnings({
               project(g, 'epsg:26986')
            },
            pattern = dumb_warning, class = 'warning')
         }
         else
            terra::crs(g) <- 'EPSG:26986'                                           #    prevent warnings when CRS is but isn't EPSG:26986 (e.g., 20Jun22_OTH_High_SWIR_Ortho.tif)
         
         suppress_warnings({
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

