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
# - build_input_stack
# - extract_training_patches 
# - spatial_train_val_split 
# - export_to_numpy 


do_prep_unet <- function(model) {
   
   
   pars <- read_yaml(file.path(the$parsdir, paste0(model, '.yml')))
   
   
}