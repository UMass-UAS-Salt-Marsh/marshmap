#' Pre-process data for U-Net
#' 
#' Creates numpy arrays ready for fitting in U-Net. Result files are placed in `<site>/unet/<model>`.
#' 
#' @param model The model name, which is also the name of a `.yml` parameter file in the `pars` 
#'    directory. This file must contain the following:
#'    - year: the year to fit
#'    - orthos: portable names of all orthophotos to include
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


do_prep_unet <- function(model) {
   
   
   pars <- read_yaml(file.path(the$parsdir, paste0(model, '.yml')))
   
   
   
   
   
   # Section 1: Setup and Helper Functions
   
   library(terra)
   library(sf)
   library(dplyr)
   library(reticulate)
   
   # Configuration
   config <- list(
      patch = 256,  # pixels
      n_channels = 8,    # RGB + NIR + RedEdge + NDVI + NDRE + DEM                      <- get this from orthos
      classes = c(3, 4, 5, 6),  # Trans1, Trans2, Trans3, High1
      class_mapping = c("3" = 0, "4" = 1, "5" = 2, "6" = 3),  # Remap for U-Net         <- do this from classes
      holdout = 0.2,
      seed = 42
   )
   
   
   
   result <- unet_prepare_site_data()
   
}