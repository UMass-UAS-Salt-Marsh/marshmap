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
#'    The shapefile is downloaded for reference, and a raster corresponding to `standard` is created.
#' @importFrom terra project rast crs writeRaster mask crop resample rasterize vect datatype
#' @importFrom sf st_read 
#' @importFrom lubridate as.duration interval
#' @importFrom pkgcond suppress_warnings
#' @importFrom tools file_path_sans_ext
#' @importFrom googledrive drive_auth
#' @export


do_gather <- function(site, pattern = '', 
                      update = TRUE, check = FALSE, field = FALSE) {
   
   
   lf <- file.path(the$modelsdir, 'gather.log')                                     # set up logging
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
   
   if((the$gather$sourcedrive %in% c('google', 'sftp')) & 
      !dir.exists(the$cachedir))                                                    #    make sure cache directory exists if needed
      dir.create(the$cachedir, recursive = TRUE)
   
   if(the$gather$sourcedrive == 'google')                                           #    authorize Google Drive if need be
      drive_auth(token = readRDS('~/.google_auth/google_drive_token.RDS'))
   
   
   if(check)
      msg('check = TRUE, so printing but not processing files', lf)
   
   
   for(i in 1:dim(sites)[1]) {                                                      # for each site,
      msg(paste0('Site ', sites$site[i]), lf)
      dir <- file.path(the$gather$sourcedir, sites$site_name[i], '/')
      
      s <- c(the$gather$subdirs, dirname(sites$standard[i]))                        #    add path to standard to subdirs in case it's not there already
      s <- gsub('/+', '/', paste0(s, '/'))                                          #    clean up slashes
      s <- unique(s)                                                                #    and drop likely duplicate
      
      x <- NULL
      for(j in resolve_dir(s, sites$share[i]))                                      #    for each subdir (with site name replacement using share name),
         x <- rbind(x, get_dir(file.path(dir, j), 
                               the$gather$sourcedrive,
                               sftp = the$gather$sftp, logfile = lf))               #       get directory
      
      t <- get_dir(file.path(dir, dirname(sites$footprint[i])), 
                   the$gather$sourcedrive, sftp = the$gather$sftp, logfile = lf)    #    Now get directory for footprint shapefile
      x <- rbind(x, t[grep('.shp$|.shx$|.prj$|.dbf$', t$name),])                    #    only want .shp, .shx, and .prj
      
      
      if(field) {                                                                   #    if we're processing field transects,
         tp <- file.path(the$gather$sourcedir, sites$site_name[i], 
                         the$gather$transects)
         t <- get_dir(tp, the$gather$sourcedrive, 
                      sftp = the$gather$sftp, logfile = lf)                         #       get transect directory
         x <- rbind(x, t[grep('.shp$|.shx$|.prj$|.dbf$', t$name),])                 #       only want .shp, .shx, .prj, and .dbf
      }
      
      
      gd <- list(dir = x, sourcedrive = the$gather$sourcedrive, 
                 cachedir = the$cachedir, sftp = the$gather$sftp)                   #    info for Google Drive or SFTP
      
      
      files <- x$name[grep('.tif$', tolower(x$name))]                               #    only want files ending in .tif
      files <- files[grep(tolower(pattern), tolower(files))]                        #    match user's pattern - this is our definitive list of geoTIFFs to process for this site
      files <- files[grep('^bad_', tolower(files), invert = TRUE)]                  #    BUT drop files that begin with 'bad_', as they're corrupted
      files <- files[!files %in% the$gather$exclude]                                #    also drop files listed in exclude
      
      
      if(length(files) != 0) {                                                      #    if there are some geoTIFFs to process,
         
         if(update) {                                                               #       if update, don't mess with files that have already been done
            sdir <- file.path(the$gather$sourcedir, sites$site_name[i])
            rdir <- resolve_dir(the$flightsdir, tolower(sites$site[i]))
            files <- files[!check_files(files, gd, sdir, rdir, addx = TRUE)]        #          see which files already exist and are up to date
         }
         
         
         if(check) {                                                                #       if check = TRUE, don't download or process anything
            msg(paste0('   ', files), lf)                                           #          but do print the source file names
            next
         }
      }
      
      
      dumb_warning <- 'Sum of Photometric type-related color channels'              #    we don't want to hear about this!
      suppress_warnings(r <- get_rast(file.path(dir, sites$standard[i]), 
                                      gd, logfile = lf), 
                        pattern = dumb_warning, class = 'warning')
      standard <- r$rast
      type <- r$type
      missing <- r$missing
      
      msg(paste0('   Processing ', length(files), ' geoTIFFs...'), lf)
      
      
      
      get_sidecars <- function(path, file, gd, logfile) {                           #    helper function: cache shapefile sidecar files
         for(ext in c('.shx', '.prj', '.dbf'))
            t <- get_file(file.path(path, sub('.shp$', ext, file)), gd, logfile) 
      }
      
      if(the$gather$sourcedrive %in% c('google', 'sftp'))                           #----Read footprint: if reading from Google Drive or SFTP,
         get_sidecars(dir, sites$footprint[i], gd, lf)                              #       load two sidecar files for shapefile into cache
      footprint <- st_read(get_file(file.path(dir, sites$footprint[i]), 
                                    gd, logfile = lf), quiet = TRUE)                #    read footprint shapefile
      
      sf <- resolve_dir(the$shapefilesdir, tolower(sites$site[i]))
      if(!dir.exists(sf))
         dir.create(sf, recursive = TRUE)
      shps <- list.files(the$cachedir, pattern = tools::file_path_sans_ext(basename(sites$footprint[i])))
      for(f in shps)
         file.copy(file.path(the$cachedir, f), sf, overwrite = TRUE, copy.date = TRUE)
      
      
      if(field) {                                                                   #----if reading field transect shapefile,
         fd <- resolve_dir(the$fielddir, tolower(sites$site[i]))                    #    results go in field/
         if(!dir.exists(fd))                                                        #       create field directory if it doesn't exist
            dir.create(fd, recursive = TRUE)
         
         
         if(!file.exists(file.path(fd, 'transects.tif'))) {                         #       if we don't already have it transect results,
            msg(' Processing field transect shapefile', lf)
            
            tp <- file.path(the$gather$sourcedir, sites$site_name[i], 
                            the$gather$transects)
            
            if(the$gather$sourcedrive %in% c('google', 'sftp'))                     #       if reading from Google Drive or SFTP,
               get_sidecars(tp, sites$transects[i], gd, lf)                         #       load three sidecar files (include .dbf) for shapefile into cache
            
            tpath <- get_file(file.path(tp, sites$transects[i]), 
                              gd, logfile = lf)                                     #       path and name of transects shapefile
            
            transects <- rasterize(vect(tpath), standard, field = 'SubCl')$SubCl |> #       convert it to raster and pull SubCl, numeric version of subclass
               crop(footprint) |>                                                   #       crop, mask, and write
               mask(footprint) |>
               writeRaster(file.path(fd, 'transects.tif'), overwrite = TRUE,
                           datatype = type, NAflag = missing)
            
            shps <- list.files(the$cachedir, pattern = tools::file_path_sans_ext(basename(sites$transects[i])))
            for(f in shps)
               file.copy(file.path(the$cachedir, f), sf, overwrite = TRUE, copy.date = TRUE)
            count$transect <- count$transect + 1
         }
      }
      
      
      
      rd <- resolve_dir(the$flightsdir, tolower(sites$site[i]))                    #    prepare result directory
      if(!dir.exists(rd))
         dir.create(rd, recursive = TRUE)
      
      
      count$tiff <- count$tiff + length(files)
      for(j in files) {                                                             #----for each target geoTIFF in site,
         msg(paste0('      processing ', j), lf)
         
         if(tryCatch({                                                              #    read the raster, skipping bad ones
            suppressWarnings(r <- get_rast(j, gd, logfile = lf))
            g <- r$rast
            type <- r$type
            missing <- r$missing
            FALSE
         }, 
         error = function(cond) {
            msg(paste0('         *** ', cond[[1]]), lf)
            msg(paste0('         *** Skipping missing or corrupted raster ', j), lf)
            TRUE
         }))
         next
         
         
         if(length(grep('SWIR|XT2', j)) == 1)                                       #    if image is SWIR (shortwave infrared),
            g <- g[[1]]                                                             #       it's 3 redundant bands, so just take first one
         
         
         if(paste(crs(g, describe = TRUE)[c('authority', 'code')], collapse = ':') != 'EPSG:4326') {
            msg(paste0('         !!! Reprojecting ', g), lf)
            g <- project(g, 'epsg:4326')
         }
         else
            terra::crs(g) <- 'EPSG:4326'                                            #    prevent warnings when CRS is but isn't EPSG:4326 (e.g., 20Jun22_OTH_High_SWIR_Ortho.tif)
         
         pkgcond::suppress_warnings({
            resample(g, standard, method = 'bilinear', threads = TRUE) |>
               crop(footprint) |>
               mask(footprint) |>
               writeRaster(file.path(rd, basename(add_x(j))), overwrite = TRUE, 
                           datatype = type, NAflag = missing)                       #    save raster (with prepended 'x' for files that start with a digit)
         }, 
         pattern = dumb_warning, class = 'warning')                                 #    resample, crop, mask, and write to result directory
      }
      msg(paste0('Finished with site ', sites$site[i]), lf)
   }
   d <- as.duration(interval(start, Sys.time()))
   msg(paste0('Run finished. ', count$tiff,' geoTIFFs and ', count$transect, ' transect shapefiles processed in ', round(d), ifelse(count$tiff == 0, '', paste0('; ', round(d / count$tiff), ' per geoTIFF.'))), lf)
}

