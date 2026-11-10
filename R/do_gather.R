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
#' @param drone If TRUE, gather and process drone imagery (geoTIFFs) and run `flights_prep`
#' @param field If TRUE, download and process the field transects if they don't already exist.
#'    The processed shapefile is saved to the shapefiles directory.
#' @param field_rasters If TRUE, also rasterize field transects (`transects.tif`) and blocks
#'    shapefiles to match `standard`. Overlaps in the shapefile with more than one subclass are
#'    erased for the transects raster. Only used for random forest models.
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
                      update, check, drone = TRUE, field, field_rasters = FALSE,
                      ignore_bad_classes, replace_ground_truth, replace_caches) {
   
   
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

   field_style <- if(is.null(the$gather$field_style)) 'old_transects' else the$gather$field_style
   if(!field_style %in% c('old_transects', 'transects', 'plots'))
      stop('field_style must be one of old_transects, transects, or plots')
   field_buffer <- if(is.null(the$gather$field_buffer)) 1 else the$gather$field_buffer
   target_crs <- if(is.null(the$gather$crs)) 'EPSG:26986' else the$gather$crs        # target projection for all results
   message('Target projection is ', target_crs, '; field style is ', field_style)
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
      
      s <- c(if(drone) the$gather$subdirs,                                          #    imagery subdirs only if we're processing drone data,
             if(drone | field_rasters) dirname(sites$standard[i]))                  #    plus path to standard if we need it
      s <- if(length(s)) gsub('/+', '/', paste0(s, '/'))                            #    clean up slashes
      s <- unique(s)                                                                #    and drop likely duplicate
      
      x <- NULL
      for(j in resolve_dir(s, sites$site[i]))                                       #    for each subdir (with site name replacement using share name),
         x <- rbind(x, get_dir(file.path(dir, j), 
                               the$gather$sourcedrive,
                               sftp = the$gather$sftp))                             #       get directory
      
      t <- get_dir(file.path(dir, dirname(sites$footprint[i])), 
                   the$gather$sourcedrive, sftp = the$gather$sftp)                  #    Now get directory for footprint shapefile
      x <- rbind(x, t[grep('.shp$|.shx$|.prj$|.dbf$', t$name),])                    #    only want .shp, .shx, and .prj
      
      
      if(field) {                                                                   #    if we're processing field data,
         if(field_style == 'old_transects') {                                       #       one shapefile per site in transects directory
            tp <- file.path(the$gather$sourcedir, the$gather$transects)
            t <- get_dir(tp, the$gather$sourcedrive,
                         sftp = the$gather$sftp)                                    #       get transect directory
            x <- rbind(x, t[grep('.shp$|.shx$|.prj$|.dbf$', t$name),])              #       only want .shp, .shx, .prj, and .dbf
            tname <- sites$transects[i]
         }
         else {                                                                     #       else, transects is the path to an all-sites GeoPackage
            tp <- dirname(file.path(the$gather$sourcedir, the$gather$transects))
            tname <- basename(the$gather$transects)
            t <- get_dir(tp, the$gather$sourcedrive, sftp = the$gather$sftp)
            x <- rbind(x, t[tolower(basename(t$name)) == tolower(tname), ])
         }
      }
      
      
      gd <- list(dir = x, sourcedrive = the$gather$sourcedrive, 
                 cachedir = the$cachedir, sftp = the$gather$sftp)                   #    info for Google Drive or SFTP
      
      
      files <- if(drone) x$name[grep('.tif$', tolower(x$name))] else character(0)   #    only want files ending in .tif (and none if drone = FALSE)
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
      }


      if(check) {                                                                   #    if check = TRUE, don't download or process anything
         if(length(files) != 0)
            message('   ', paste(files, collapse = '\n   '))                        #       but do print the source file names
         next
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

      if(!crs_matches(footprint, target_crs)) {
         message('         !!! Reprojecting ', basename(sites$footprint[i]), ' to ', target_crs)
         footprint <- st_transform(footprint, crs = target_crs)
         footprint <- st_make_valid(footprint)                                      #    fix any geometries broken by reprojection
      }
      
      sf <- resolve_dir(the$shapefilesdir, tolower(sites$site[i]))
      if(!dir.exists(sf))
         dir.create(sf, recursive = TRUE)
      
      st_write(footprint, 
               file.path(sf, paste0(toupper(sites$site[i]), '_footprint.shp')),
               append = FALSE, quiet = TRUE)                                        #    save reprojected footprint
      
      if(drone | field_rasters) {                                                   #----Standard: only needed for imagery or field rasters ----
         std <- file.path(rd, basename(sites$standard[i]))                          #    path to stored standard file
         message('   Standard: ', basename(std))

         if(!file.exists(std)) {                                                    #    if we don't have the standard in our files yet,
            r <- suppress_warnings(get_rast(
               get_file(file.path(dir, sites$standard[i]), gd)),
               pattern = dumb_warning, class = 'warning')                           #       get it from the remote drive or the cache
            if(!dir.exists(rd))
               dir.create(rd, recursive = TRUE)
            g <- r$rast
            if(!crs_matches(g, target_crs)) {
               message('         !!! Reprojecting standard ', basename(std), ' to ', target_crs)
               g <- suppress_warnings(project(g, target_crs),                       #       reproject it to target projection
                                      pattern = dumb_warning, class = 'warning')
            }
            suppress_warnings({
               g |>
                  crop(footprint) |>
                  mask(footprint) |>
                  writeRaster(std, overwrite = TRUE,
                              datatype = r$type, NAflag = r$missing)                #    save raster
            },
            pattern = dumb_warning, class = 'warning')                              #    resample, crop, mask, and write to result directory
         }

         r <-get_rast(std)                                                          #    new get the standard
         standard <- r$rast
         type <- r$type
         missing <- r$missing                                                       #    *** these are fucking mess. Need to rethink how I do them--they won't be right for transects or blocks
      }


      if(drone)
         message('   --- Processing ', length(files), ' geoTIFFs ---')
      
      
      shps <- list.files(the$cachedir, pattern = tools::file_path_sans_ext(basename(sites$footprint[i])))
      for(f in shps)
         file.copy(file.path(the$cachedir, f), sf, overwrite = TRUE, copy.date = TRUE)
      
      
      if(field) {                                                                   #----if reading field transect shapefile, ----
         fd <- resolve_dir(the$fielddir, tolower(sites$site[i]))
         if(!dir.exists(fd))                                                        #       create field directory if it doesn't exist
            dir.create(fd, recursive = TRUE)
         
         
         trpath <- resolve_dir(the$shapefilesdir, tolower(sites$site[i]))
         trname <- paste0(toupper(sites$site[i]), '_transects.shp')
         tout <- file.path(trpath, trname)                                          #       processed transects shapefile

         if(is.na(tname) || tname == '')                                            #       if we don't have transects for this site, (old_transects only)
            message(' No field transects for site ', sites$site[i])
         else if(!file.exists(tout) || file.mtime(tout) < source_mtime(file.path(tp, tname), gd) |
                 replace_ground_truth |
                 (field_rasters && !file.exists(file.path(fd, 'transects.tif')))) { #       if we don't already have transect results (or raster, if wanted) or they're outdated or replace_ground_truth,
            message(' Processing field data (', field_style, ')')

            if(field_style == 'old_transects' &&
               the$gather$sourcedrive %in% c('google', 'sftp'))                     #       if reading a shapefile from Google Drive or SFTP,
               get_sidecars(tp, tname, gd)                                          #       load three sidecar files (include .dbf) for shapefile into cache

            tpath <- get_file(file.path(tp, tname), gd)                             #       path and name of field data file


            shp <- read_field(tpath, field_style, sites$site[i], field_buffer)      #       read field data and buffer if need be
            if(nrow(shp) == 0) {
               message('*** No field data for site ', sites$site[i], ' in ', tname)
            }
            else {
               shp <- st_make_valid(shp)                                            #       fix any invalid geometries
               shp <- shp[st_is_valid(shp), ]                                       #       drop anything that survived invalid

               if(!crs_matches(shp, target_crs)) {
                  message('         !!! Reprojecting ', basename(tpath), ' to ', target_crs)
                  shp <- st_transform(shp, crs = target_crs)
                  shp <- st_make_valid(shp)                                         #       fix any geometries broken by reprojection
                  shp <- shp[st_is_valid(shp), ]                                    #       drop anything that survived invalid
               }

               u <- sort(unique(shp$subclass))
               bad <- u[!u %in% read_pars_table('classes')$subclass]
               if(length(bad) > 0) {
                  if(ignore_bad_classes)
                     message('***** Ground truth shapefile has bad classes ', paste(bad, collapse = ', '))
                  else
                     stop('Ground truth shapefile has bad classes ', paste(bad, collapse = ', '))
               }
               
               shp$poly <- 1:nrow(shp)                                              #       add unique poly ids

               for(j in 1:5)                                                        #       add 5 _bypoly columns
                  shp[[paste0('bypoly', sprintf('%02d', j))]] <- shuffle(shp$subclass)

               shp <- shapefile_names(shp)                                          #       truncate long names so st_write doesn't mangle the rest

               if(!is.null(shp$reject)) {                                           #       if there's a reject column (old_transects),
                  tr_rejname <- paste0(toupper(sites$site[i]), '_transects_incl_rejects.shp')
                  st_write(shp, file.path(trpath, tr_rejname),
                           append = FALSE, quiet = TRUE)                            #          save the processed transects shapefile with rejected rows intact
                  shp <- shp[is.na(shp$reject) | shp$reject == 0, ]                 #          and DROP rejected rows
               }

               suppress_warnings(st_write(shp, tout, append = FALSE, quiet = TRUE), #       save the processed transects shapefile
                                 pattern = 'abbreviated|created as String|truncated',
                                 class = 'warning')                                 #       (we don't care that shapefiles mangle names and dates)
               message('   ', nrow(shp), ' field polys written to ', trname)


               count$transect <- count$transect + 1


               if(field_rasters) {                                                  #       if making field rasters (random forest only),
                  shp <- overlaps(shp, 'subclass', all = FALSE)                     #          remove unequal overlaps for raster transects (all years) ----

                  suppress_warnings(transects <-                                    #          mask gives a bogus warning that CRS do not match
                                       rasterize(shp, standard,
                                                 field = 'poly')$poly |>            #          convert it to raster populated with unique poly id
                                       crop(footprint) |>                           #          crop, mask, and write
                                       mask(footprint) |>
                                       writeRaster(file.path(fd, 'transects.tif'), overwrite = TRUE,
                                                   datatype = type, NAflag = missing))

                  if(all(is.na(values(transects)))) {
                     message('*** Ground truth data are all missing!!')
                     unlink(file.path(fd, 'transects.tif'))
                  }
               }
            }
         }
      }


      bd <- resolve_dir(the$blocksdir, tolower(sites$site[i]))                      #----Read blocks shapefiles from local drive, correct projection assumed ----
      if(field_rasters && dir.exists(bd)) {                                         #    if making field rasters and the blocks directory exists, have a look
         
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
         
         
         if(!crs_matches(g, target_crs)) {
            message('         !!! Reprojecting ', j, ' to ', target_crs)
            g <- suppress_warnings({
               project(g, target_crs)
            },
            pattern = dumb_warning, class = 'warning')
         }
         else
            terra::crs(g) <- terra::crs(standard)                                   #    prevent warnings when CRS is but isn't the target (e.g., 20Jun22_OTH_High_SWIR_Ortho.tif)
         
         suppress_warnings({
            resample(g, standard, method = 'bilinear', threads = TRUE) |>
               crop(footprint) |>
               mask(footprint) |>
               writeRaster(file.path(rd, basename(j)), overwrite = TRUE, 
                           datatype = type, NAflag = missing)                       #    save raster
         }, 
         pattern = dumb_warning, class = 'warning')                                 #    resample, crop, mask, and write to result directory
      }
      
      
      if(drone)
         flights_prep(site, replace_caches = replace_caches)                        #    now count missing values and cache images for screen
      
      message('Finished with site ', sites$site[i])
   }
   d <- as.duration(interval(start, Sys.time()))
   message('Run finished. ', count$tiff,' geoTIFFs and ', count$transect, ' transect shapefiles processed in ', round(d), ifelse(count$tiff == 0, '', paste0('; ', round(d / count$tiff), ' per geoTIFF.')))
}

