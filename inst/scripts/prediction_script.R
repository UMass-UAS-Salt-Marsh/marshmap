

if(FALSE) {
   
   devtools::load_all(".")
   library(peakRAM)
   library(terra)
   # remotes::install_github('ethanplunkett/rasterPrep')
   library(rasterPrep)
  
   target <- 'subclass'                               # this will be pulled from names(fit$train)[1]
    
 ###  sample('oth', p = 0.2)
   
   
#   fit('oth', years = 2019:2020, reread = TRUE)
#   fit('oth', years = 2018:2021, reread = TRUE)                                                            # this is my favorite model at the moment. It's in fit_oth_2025-Apr-29_15-19.RDS
#   fit('oth', years = 2018:2021, reread = TRUE, vars = rownames(the$fit$import$importance)[1:20])
#   
#   
 #  the$fit <- readRDS('/work/pi_cschweik_umass_edu/marsh_mapping/models/fit_oth_2025-Apr-28_13-54.RDS')   # read fit for 2018-2021
   
   the$fit <- readRDS('c:/work/etc/saltmarsh/models/fit_oth_2025-May-05_15-53.RDS')                           ############# FOR TESTING
   the$site <- 'oth'
   #fit('oth', years = 2018:2021, reread = TRUE, vars = rownames(the$fit$import$importance)[1:40])
#   fit('oth', years = 2018:2021, reread = TRUE, vars = 'X04Aug21_OTH_Low_SWIR_1')
   
   
###   fit('oth', reread = TRUE)
   # fit('oth', vars = pickvars(40))
   # the$fit <- readRDS('/work/pi_cschweik_umass_edu/marsh_mapping/models/fit_2025-Apr-24_16-08')
   
   
   #the$fit <- readRDS('/work/pi_cschweik_umass_edu/marsh_mapping/models/fit_oth_2025-Apr-27_18-13.RDS')
   
   
   
   path <- '/work/pi_cschweik_umass_edu/marsh_mapping/data/oth/flights'
   rpath <- '/work/pi_cschweik_umass_edu/marsh_mapping/data/oth/predicted'
   
   
   path <- 'C:/Work/etc/saltmarsh/data/oth/flights'                                                        ############## for testing
   rpath <- 'C:/Work/etc/saltmarsh/data/oth/predicted'
   
   
   
   x <- names(the$fit$fit$trainingData)[-1]
   x <- sub('^X', '', x)                              # drop leading X
   x <- sub('_\\d+$', '', x)                          # drop band
   x <- unique(x)                                     # and remove dups
   
   print(x)
   
   rasters <- rast(file.path(path, paste0(x, '.tif')))
   names(rasters) <- sub('^(\\d)', 'X\\1', names(rasters))                             # files with leading digit get X prepended by R  
   
   rasters <- rasters[[names(rasters) %in% names(the$fit$fit$trainingData)[-1]]]       # drop bands we don't want
   
 #   clip <- ext(c(-70.86254419, -70.86135362, 42.77072136, 42.7717978))               # small clip
  #  clip <- ext(c(-70.86452506, -70.86040917, 42.76976948, 42.77283781))                # larger clip: 38 min, 69 GB
  #  
  
    clip <- the$clip$oth$small                                             # we'll have a clip argument, with clips from pars.yml, like this
    rasters <- crop(rasters, ext(clip))
   
    
    ts <- stamp('2025-Mar-25_13-18', quiet = TRUE)                                     # set format for timestamp in filename                         
    fx <- file.path(rpath, paste0('predict_', the$site, '_', ts(now())))               # base result filename
    f0 <- paste0(fx, '_0.tif')                                                         # preliminary result filename
    f <- paste0(fx, '.tif')                                                            # final result filename
    
    peakRAM(pred <- terra::predict(rasters, the$fit$fit, cpkgs = 'ranger', cores = 1, na.rm = TRUE))    # do a prediction for the model
   
    
    levs <- levels(pred$class)[[1]]                                                             # replace values with levels
    levs$class <- as.numeric(levs$class)
    names(levs)[2] <- target                                                                 
    # pred2 <- subst(as.numeric(pred), from = levs$value, to = levs$class)
    pred2 <- pred
    
    writeRaster(pred2, f0, overwrite = TRUE, datatype = 'INT1U', progress = 1, memfrac = 0.8)      # save the geoTIFF

    classes <- read_pars_table('classes')                                                          # read classes file
    classes <- classes[, grep(paste0('^', target), names(classes))]           # target level in classes
    vat <- merge(levs, classes, sort = TRUE)
    vat <- vat[, c(2, 1, 3:ncol(vat))]                                                               # back to the order I want, with value first
    names(vat) <- c('value', target, 'name', 'color')
    
    
    vat2 <- vat[, c('value', 'color')]
    vat2$category <-  paste0('[', vat[, target], '] ', vat$name)
    vrt.file <- addColorTable(f0, table = vat2)
    
    makeNiceTif(source = vrt.file, destination = f, overwrite = TRUE, overviewResample = 'nearest', stats = FALSE, vat = FALSE)
    
    
    addVat(f, attributes = vat)                        # <<-----------------------------------------
    
    
  
   plot(tt, col = vat$color)                                                  # plot in R
   
  print(paste0('Done!! Results are in ', f))
 
   
   
   
   
     
}