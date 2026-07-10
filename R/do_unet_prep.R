#' Pre-process data for U-Net
#' 
#' Creates numpy arrays ready for fitting in U-Net. Result files are placed in `<site>/unet/<model>`.
#' 
#' @param model The model name, which is also the name of a `.yml` parameter file in `<pars>/unet/` 
#'    This file must contain the following:
#'    - years: the year(s) of field data to fit
#'    - orthos: file names of all orthophotos to include
#'    - patch: size in pixels
#'    - depth: number of of downsampling stages
#'    - classes: vector of target classes
#'    - transects: base name of field transects shapefile (default: "transects")
#'    - holdout_col: holdout set to use (uses bypoly<holdout>). Holdout sets are created by
#'      `gather`, numbering each poly from 1 to 10, repeating if necessary. There are 5 sets to 
#'      choose from.
#'    - cv: number of cross-validations. Use 1 for a single model, up to 5 for five-fold 
#'      cross-validation. Cross-validations are systematic, not random. Since there are only 10 
#'      sets in each bypoly, the number of cross-validations is limited by the values of val 
#'      and test. 
#'    - val: validation polys from `holdout_col`. Use NULL to skip validation, or a vector of 
#'      the validation polys for the first cross-validation (these will be incremented for
#'      subsequent validations). For 20% validation holdout, use `val = c(1, 6)`. This will use
#'      `bypoly01 %in% c(1,6)`` for the first cross-validation, `c(2, 7)` for the second, and so 
#'      on. 
#'    - test: test polys from `holdout_col`, as with `val`.
#'    - overlap: Proportion overlap of patches
#'    - upscale: number of cells to upscale (default = 1). Use 3 to upscale to 3x3, 5 for 5x5, etc.
#'    - smooth: number of cells to include in moving window mean (default = 1). Use 3 to smooth to 3x3, etc.
#' @param save_gis If TRUE, saves GIS data for assessment and debugging
#' @importFrom yaml read_yaml
#' @importFrom terra rast values global quantile clamp ext res rast rasterize crs
#' @importFrom sf st_as_sf st_buffer st_is_valid st_make_valid st_intersects st_coordinates st_crop st_nearest_feature 
#' @importFrom reticulate import
#' @export


# Notes:
# - I may want to change this to accept portable names, or a choice of portable or file names
# - Claude has me quantile-scaling spectral data, standardizing DEM, and leaving NDVI and NDRI as-is. Is this correct?


do_unet_prep <- function(model, save_gis) {
   
   
   config <- read_yaml(file.path(the$parsdir, 'unet', paste0(model, '.yml')))
   config <- unet_config_defaults(config)                                     # fill defaults + derive helper fields

   output_dir <- file.path(resolve_dir(the$unetdir, config$site), model, 'patches')


   setup       <- unet_prep_setup(config)                                     # ----- input stack + prepared transects
   input_stack <- setup$input_stack
   transects   <- setup$transects


   for(i in seq_len(config$cv)) {                                             # ----- For each cross-validation iteration,
      message('======== Iteration ', i, ' of ', config$cv, ' ========')
      message('   Creating train/validate/test split...')
      split <- unet_spatial_train_val_split(                                  #    --- split into training, validation, and test data
         transects = transects,
         holdout_col = config$holdout_col, 
         cv = i, val = config$val, test = config$test)                                                                                             
      
      
      message('   Extracting patches...')                                     #    --- extract patches
      patches <- unet_extract_training_patches(
         input_stack = input_stack,
         transects = transects,
         train_ids = split$train_ids,
         validate_ids = split$validate_ids,
         test_ids = split$test_ids,
         patch = config$patch,
         overlap = config$overlap,
         classes = config$classes,
         class_mapping = config$class_mapping
      )
      
      
      patch_stats <- unet_patch_stats(patches)                                #    --- get and display stats on patches, including purity histogram
      
      
      message('   Exporting to numpy...')                                     #    --- export to numpy
      unet_export_to_numpy(
         patches = patches,
         output_dir = output_dir,
         site = config$site,
         class_mapping = config$class_mapping,
         set = i
      )

      # Save poly counts for summary.txt (written by do_train)
      poly_counts <- list(
         total = table(transects$subclass),
         train = table(transects$subclass[transects$poly %in% split$train_ids]),
         test  = table(transects$subclass[transects$poly %in% split$test_ids])
      )
      saveRDS(poly_counts, file.path(output_dir, paste0('set', i), 'poly_counts.rds'))

      # Save per-class pixel counts for summary.txt (labeled pixels in train/test patches)
      orig_cls   <- as.integer(names(config$class_mapping))
      train_idx  <- which(patches$has_train)
      test_idx   <- which(patches$has_test)
      count_pix  <- function(idx, masks) {
         sapply(orig_cls, function(cls) {
            remapped <- as.integer(config$class_mapping[[as.character(cls)]])
            sum(patches$labels[idx,,] == remapped & masks[idx,,] == 1, na.rm = TRUE)
         })
      }
      pixel_counts <- list(
         train = setNames(count_pix(train_idx, patches$train_masks), orig_cls),
         test  = setNames(count_pix(test_idx,  patches$test_masks),  orig_cls)
      )
      saveRDS(pixel_counts, file.path(output_dir, paste0('set', i), 'pixel_counts.rds'))

      message('')
   }
   
   
   message('Data preparation complete!')
}
