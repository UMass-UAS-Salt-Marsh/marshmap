#' Create missing our outdated cached images for screen()
#' 
#' @param site site, using 3 letter abbreviation
#' @keywords internal


flights_cache <- function(site) {
   
   
   x <- get_flights_db(site)
   
   dir <- resolve_dir(the$flightsdir, site)                             # here's the flights directory
   cdir <-file.path(dir, 'cache')                                       # and the cache directory
   if(!dir.exists(cdir))
      dir.create(cdir, recursive = TRUE)                                # create cache if it doesn't exist
   
   cached <- c('full.png', 'inset1.png', 'inset2.png')                  # different cache types
   
   fn <- rep(x$name, each = length(cached))                             # filename => filename x cache type
   fd <- file.mtime(file.path(dir, fn))                                 # ortho dates on disk
   
   cn <- file.path(cdir, 
                   paste(sub('.tif', '', fn, fixed = TRUE), 
                         cached, sep = '_'))
   cd <- file.mtime(cn)                                                 # cached image dates on disk
   
   good <- !is.na(cd) & cd > fd                                         # these cached files exist and are up-to-date
   
   if(all(good)) {                                                      # if they're all good, we're done
      message('All cached images are up-to-date')
      return()
   }
   
   
   files <- unique(fn[!good])                                           # these are the orthos on our to-do list
   message('Building cached images for ', length(files), ' orthos...')
   
   sites <- read_pars_table('sites')
   footfile <- file.path(resolve_dir(the$shapefilesdir, site), 
                         basename(sites$footprint[sites$site == site]))
   footprint <- st_read(footfile, quiet = TRUE)                         # read site footprint
   
   
   for(f in files) {                                                    # for each file,
      data <- rast(file.path(dir, f))                                   #    read raster
      
      if(x$sensor[match(f, x$name)] == 'mica')                          #    reverse RGB order for Mica
         rgb <- 3:1
      else
         rgb < 1:3
      
      flights_image(data, cdir, f, 
                    rgb, 'full', footprint)                             #    and make 3 cached images
      flights_image(center_zoom(data, 0.20), cdir, f, 
                    rgb, 'inset1', footprint)
      flights_image(center_zoom(data, 0.05), cdir, f, 
                    rgb, 'inset2', footprint)
   }
   
   
   message('All images cached for site ', toupper(site))
}