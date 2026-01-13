#' Pre-process data for U-Net
#' 
#' Creates numpy arrays ready for fitting in U-Net. Result files are placed in `<site>/unet/<model>`.
#' 
#' @param model The model name, which is also the name of a `.yml` parameter file in the `pars` 
#'    directory. This file must contain the following:
#'    - year: the year to fit
#'    - orthos: file names of all orthophotos to include
#'    - patch: size in pixels
#'    - depth: number of of downsampling stages
#'    - classes: vector of target classes
#'    - holdout: percent of data to hold out for validation
#' @importFrom yaml read_yaml
#' @export


# fns:
# [x] 1. unet_build_input_stack
# [ ] 2. unet_extract_training_patches 
# [ ] 3. unet_spatial_train_val_split 
# [ ] 4. unet_export_to_numpy 
# 
# libs:
#    library(terra)
#    library(sf)
#    library(dplyr)
#    library(reticulate)

# Notes:
# - I may want to change this to accept portable names, or a choice of portable or file names
# - Claude has me quantile-scaling spectral data, standardizing DEM, and leaving NDVI and NDRI as-is. Is this correct?


do_prep_unet <- function(model) {
   
   
   
   library(sf)                         # TEMPORARY, for development
   library(terra)
   
   
   config <- read_yaml(file.path(the$parsdir, paste0(model, '.yml')))
   
   config$fpath <- resolve_dir(the$flightsdir, config$site)
   config$bands <- unlist(lapply(config$orthos, function(x) 
      nlyr(rast(file.path(config$fpath, x)))))                                # number of bands for each ortho
   config$n_channels <- sum(config$bands)                                     # total number of channels
   
   config$type <- rep('image', length(config$orthos))                         # type for each ortho
   config$type[grep('__NDVI', config$orthos)] <- 'ndvi'
   config$type[grep('__NDRE', config$orthos)] <- 'ndre'
   config$type[grep('DEM', config$orthos)] <- 'dem'

   config$class_mapping <- as.list(0:(length(config$classes) - 1))
   names(config$class_mapping) <- config$classes                              # class mapping
   config$seed <- 42                                                          # random seed for repeatability
   
   
   transect_file <- file.path(resolve_dir(the$shapefilesdir, config$site), get_sites(config$site)$transects)
   output_dir <- file.path(resolve_dir(the$unetdir, config$site), model)
   

   # 1. Build input stack
   message("Building input stack...")
   input_stack <- unet_build_input_stack(config)                              # ----- build input stack
   
   
   
   message("Loading transects...")
   transects <- st_read(transect_file, 
                        promote_to_multi = FALSE, quiet = TRUE)               # ----- read transects
   
   
   ###  ********************************** TEMPORARY CODE **********************************
   transects <- st_zm(transects, drop = TRUE)                                 # DROP Z VALUES - this will happen in gather
   message('Reprojecting...   [this is temporary, pending reprojection change in gather')
   transects <- st_transform(transects, 'epsg:26986')                                     
   message('Done projecting')
   ###  ************************************************************************************
   
   
   names(transects) <- tolower(names(transects))                              # name cases aren't consistent, of course
   transects <- transects[transects$subclass %in% config$classes, ]           # filter to target classes
   message(nrow(transects), ' polys in transects for classes ', paste(config$classes, collapse = ', '))
   if(nrow(transects) == 0)
      stop('No transect data for these classes')
   
  
   message("Extracting patches...")                                           # ----- extract patches
   patches <- unet_extract_training_patches(
      input_stack = input_stack,
      transects = transects,
      patch = config$patch,
      overlap = 0.5,
      classes = config$classes,
      class_mapping = config$class_mapping
   )                                                                          # ----- extract training patches
   
   
   patch_stats <<- unet_patch_stats(patches)                                  # ----- get and display stats on patches, including purity histogram
   
   # ---------------------- done to here ----------------------
   browser()
   
   
   # 4. Train/val split
   message("Creating train/validate split...")                                # ----- split into training and validation data
   split_indices <- unet_spatial_train_val_split(
      patches = patches,
      transects = transects,
      holdout = config$holdout,
      seed = config$seed
   )                                                                          
   
   
   message("Exporting to numpy...")                                           # ----- export to numpy
   unet_export_to_numpy(
      patches = patches,
      split_indices = split_indices,
      output_dir = output_dir,
      site = site
   )
   
   
   message("Data preparation complete!")
   
   return(list(
      patches = patches,
      split_indices = split_indices,
      input_stack = input_stack,
      transects = transects
   ))
}




