#' Pre-process data for U-Net
#' 
#' Creates numpy arrays ready for fitting in U-Net. Result files are placed in `<site>/unet/<model>`.
#' 
#' @param model_name The model name, which is also the name of a `.yml` parameter file in the `pars` 
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
# - 1. unet_build_input_stack
# - 2. unet_extract_training_patches 
# - 3. unet_spatial_train_val_split 
# - 4. unet_export_to_numpy 
# 
# libs:
#    library(terra)
#    library(sf)
#   library(dplyr)
#    library(reticulate)

# Notes:
# - I may want to change this to accept protable names, or a choice of portable or file names    


do_prep_unet <- function(model_name) {
   
   
   config <- read_yaml(file.path(the$parsdir, paste0(model_name, '.yml')))
   
   fpath <- resolve_dir(the$flightsdir, config$site)
   config$bands <- unlist(lapply(config$orthos, function(x) 
      nlyr(rast(file.path(fpath, x)))))                                       # number of bands for each ortho
   config$n_channels <- sum(config$bands)                                     # total number of channels
   
   config$type <- rep('image', length(config$orthos))                         # type for each ortho
   config$type[grep('__NDVI', config$orthos)] <- 'ndvi'
   config$type[grep('__NDRE', config$orthos)] <- 'ndre'
   config$type[grep('DEM', config$orthos)] <- 'dem'
 #  config$type <- unlist(lapply(seq_along(config$bands), function(x) rep(config$type[x], config$bands[x])))
   
   config$class_mapping <- as.list(0:(length(config$classes) - 1))
   names(config$class_mapping) <- config$classes                              # class mapping
   config$seed <- 42                                                          # random seed for repeatability
   
   
   transect_file <- file.path(resolve_dir(the$flightsdir, site), get_sites(site)$transects)
   output_dir <- file.path(resolve_dir(the$unetdir, site), model_name)
   
   
   
   
   # Define which ortho to use (your portable name)
   selected_ortho <- "ortho_mica_fall_2022_low"  # Example - pick your best one
   
   # Lookup tables (you'll need to create these for your data)
   # Map portable names to actual filenames
   ortho_lookup <- c(
      "ortho_mica_fall_2022_low" = "26Aug22_OTH_Low_Mica_Ortho.tif",
      # ... add all your orthos
   )
   
   dem_lookup <- c(
      "ortho_mica_fall_2022_low" = "26Aug22_OTH_Low_Mica_DEM.tif",
      # ... matching DEMs
   )
   
   # 1. Build input stack
   message("Building input stack...")
   input_stack <- unet_build_input_stack(fpath, config$orthos)
   
   
   
   
   
   # 2. Load transects
   message("Loading transects...")
   transects <- st_read(transect_file)
   
   # Filter to target classes
   transects <- transects %>% 
      filter(Subclass %in% config$classes)
   
   message("Transects with target classes: ", nrow(transects))
   
   # 3. Extract patches
   message("Extracting patches...")
   patch_data <- unet_extract_training_patches(
      input_stack = input_stack,
      transects = transects,
      patch = config$patch,
      overlap = 0.5,
      classes = config$classes,
      class_mapping = config$class_mapping
   )
   
   # 4. Train/val split
   message("Creating train/val split...")
   split_indices <- unet_spatial_train_val_split(
      patch_data = patch_data,
      transects = transects,
      holdout = config$holdout,
      seed = config$seed
   )
   
   # 5. Export to numpy
   message("Exporting to numpy...")
   unet_export_to_numpy(
      patch_data = patch_data,
      split_indices = split_indices,
      output_dir = output_dir,
      site = site
   )
   
   message("Data preparation complete!")
   
   return(list(
      patch_data = patch_data,
      split_indices = split_indices,
      input_stack = input_stack,
      transects = transects
   ))
}




