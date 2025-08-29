#' Produce geoTIFF maps of predicted vegetation cover from fitted models
#' 
#' Console command to launch a prediction run via `do_map`, typically in a batch job on Unity.
#' 
#' Side effects:
#' 1. writes a geoTIFF, `<result>.tif` with, and a run info file
#' 2. `<runinfo>.RDS`, with the following:
#'    1. Time taken for the run (s)
#'    2. Maximum memory used (GB)
#'    3. Raster size (M pixel)
#'    4. R error, or NULL for success
#' 
#' Requires `rasterPrep`. Install it with:
#'    `remotes::install_github('ethanplunkett/rasterPrep')`
#' 
#' @param fitid id in the fits database (NULL if not specified)
#' @param fitfile Full specification of an RDS file with the fit object
#' @param site Three letter site code. If fitting from a fit id that was built
#'   on a single site, you may omit `site` to map the same site (this is the
#'   most common situation). If you want to map sites other than the site the
#'   model was built on, or the model was built on mutiple sites, `site` is
#'   required.
#' @param clip Optional clip, vector of `xmin`, `xmax`, `ymin`, `ymax`
#' @param rep Throwaway argument to make `slurmcollie` happy
#' @importFrom peakRAM peakRAM
#' @importFrom terra ext predict levels writeRaster ncell
#' @importFrom rasterPrep addColorTable makeNiceTif addVat
#' @importFrom lubridate as.duration seconds
#' @export


do_map <- function(site, fitid, fitfile, clip, rep = NULL) {
   
   
   if(!is.null(clip))                                                         # if there's a clip, modify result name
      cr <- paste0('_clip_', round(extent_area(clip)), '_ha')
   else
      cr <- ''
   result <- file.path(resolve_dir(the$mapsdir, site),
                       paste0('map_', site, cr))                              # result path and name, sans extension
   
   if(!dir.exists(dirname(result)))                                           # make sure result directory exists
      dir.create(dirname(result), recursive = TRUE)
   
   r <- (as.numeric(Sys.time()) %% 1) * 1e7                                   # random part of name to prevent collisions
   f0 <- paste0(result, '_0', r, '.tif')                                      # preliminary result filename
   f0x <- paste0(result, '_0', r, '.*')                                       # all preliminary result files for later deletion
   f <- paste0(result, '.tif')                                                # final result filename
   
   
   model <- readRDS(fitfile)$model_object
   target <- as.character(model$terms[[2]])                                   # get target level, typically 'subclass'
   
   
   x <- names(model$trainingData)[-1]                                         # get source raster names from bands
   y <- sub('_\\d+$', '', x)                                                  # drop band number
   ###  band <- substring(sub('(.*)(_\\d+$)', '\\2', x), 2)                        # and get band number         DON'T NEED THIS                                     
   y <- sub('mean_w', 'mean-w', y)   # THIS BULLSHIT IS JUST TO GET IT WORKING NOW. NEED TO RESOLVE - VS _ IN DERIVED NAMES. GRR. ********************
   files <- find_orthos(site, paste(y, collapse = '+'))$file                  # get file names to read
   
   files <- unique(files)                                                     # and remove dups
   
   
   sourcedir <- resolve_dir(the$flightsdir, site)
   rasters <- rast(file.path(sourcedir, files))                               # get rasters with our bands
   names(rasters) <- x
   
   
   #  names(rasters) <- sub('^(\\d)', 'X\\1', names(rasters))                    # files with leading digit get X prepended by R  
   
   rasters <- rasters[[names(rasters) %in% names(model$trainingData)[-1]]]    # drop bands we don't want - now we have target bands
   
   if(!is.null(clip))                                                         # if clip is provided,
      rasters <- crop(rasters, ext(clip))                                     #    clip result
   mpix <- ncell(rasters)
   
   cat('Predicting...\n')
   pred <- terra::predict(rasters, model, cpkgs = model$method, 
                          cores = 1, na.rm = TRUE)                            # prediction for the model
   # odd: 10 cores uses 3x memory, but takes twice as long as 1 core. 2 cores isn't really better than 1 core either.
   # cores = cores  ############### ******************************************** need to get the number of cores from call!
   
   writeRaster(pred, f0, overwrite = TRUE, datatype = 'INT1U', progress = 1, 
               memfrac = 0.8)                                                 # save the preliminary prediction as a geoTIFF
   
   levs <- terra::levels(pred$class)[[1]]                                     # get class levels from prediction
   levs$class <- as.numeric(sub('^class', '', levs$class))                    # make sure they're numeric with no "class"
   names(levs)[2] <- target                                                   # use target (e.g., 'subclass') as class name                                                                                 
   
   classes <- read_pars_table('classes')                                      # read classes file
   classes <- classes[, grep(paste0('^', target), names(classes))]            # target level in classes
   vat <- merge(levs, classes, sort = TRUE)                                   # join levels in predict with classes
   vat <- vat[, c(2, 1, 3:ncol(vat))]                                         # back to proper, with value first
   names(vat) <- c('value', target, 'name', 'color')                          # drop back to generic names, except for target
   vat[, target] <- as.integer(vat[, target])                                 # force this to be integer
   
   vat2 <- vat[, c('value', 'color')]                                         # make a version of the vat for addColorTable
   vat2$category <-  paste0('[', vat[, target], '] ', vat$name)               # with labels that include numeric class and name, as e.g. [1] Low marsh
   vrt.file <- addColorTable(f0, table = vat2)                                # and add the standard colors
   
   makeNiceTif(source = vrt.file, destination = f, overwrite = TRUE,          # make a nice TIFF with colors and overviews and add the VAT
               overviewResample = 'nearest', stats = FALSE, vat = TRUE)
   addVat(f, attributes = vat)                    
   
   unlink(f0x)                                                                # delete preliminary files
   
}
