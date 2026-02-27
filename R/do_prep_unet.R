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


do_prep_unet <- function(model, save_gis) {
   
   
   config <- read_yaml(file.path(the$parsdir, 'unet', paste0(model, '.yml')))
   
   config$fpath <- resolve_dir(the$flightsdir, config$site)
   config$bands <- unlist(lapply(config$orthos, function(x) 
      nlyr(rast(file.path(config$fpath, x)))))                                # number of bands for each ortho
   config$n_channels <- sum(config$bands)                                     # total number of channels
   
   config$type <- rep('image', length(config$orthos))                         # type for each ortho
   config$type[grep('__NDVI', config$orthos)] <- 'ndvi'
   config$type[grep('__NDRE', config$orthos)] <- 'ndre'
   config$type[grep('DEM', config$orthos)] <- 'dem'
   
   config$class_mapping <- as.list(0:(length(config$classes) - 1))            # 0:(n-1) classes for U-Net
   names(config$class_mapping) <- config$classes                              # mapping to our class numbers
   config$seed <- 42                                                          # random seed for repeatability
   
   if(is.null(config$reclass))                                                # default: no reclassifying
      config$reclass <- ''
   
   if(is.null(config$upscale))                                                # default: no upscaling
      config$upscale <- 1
   
   if(is.null(config$smooth))                                                 # default: no smoothing
      config$smooth <- 1
   
   if(is.null(config$holdout_col))                                            # default: use bypoly01
      config$holdout_col <- 1
   
   if(is.null(config$cv))                                                     # default: 5 cross-validation iterations
      config$cv <- 5
   
   if(is.null(config$val))                                                    # default: no validation holdouts
      config$val <- NULL
   
   if(is.null(config$test))                                                   # default: use c(1,6) for the first iteration, c(2,7) for the second, and so on
      config$test <- c(1,6)
   
   if(config$cv + max(c(config$val, config$test, 0)) - 1 > 10)
      stop('Too many cross-validation iterations given values of val and test')
   
   
   transect_file <- file.path(resolve_dir(the$shapefilesdir, config$site), paste0(toupper(config$site), '_transects.shp'))
   output_dir <- file.path(resolve_dir(the$unetdir, config$site), model)
   
   
   # 1. Build input stack
   message('Building input stack...')
   input_stack <- unet_build_input_stack(config)                              # ----- build input stack
   
   
   message('Loading transects...')
   transects <- st_read(transect_file, 
                        promote_to_multi = FALSE, quiet = TRUE)               # ----- read transects
   
   if(config$reclass != '') {                                                 # if reclassifying transects (for multi-stage models),
      classes <- read_pars_table('classes')                                   #    read classes file
      transects$subclass <- 
         classes[match(transects$subclass, classes$subclass), config$reclass] #    and reclassify
      message('Reclassified subclass to ', config$reclass)
   }
   
   
   transects <- transects[transects$subclass %in% config$classes, ]           # filter to target classes
   transects <- transects[transects$year %in% config$years, ]                 # and to years
   transects <- overlaps(transects, 'subclass')                               # remove overlapping polys that don't agree
   message(nrow(transects), ' polys in transects for classes ', paste(config$classes, collapse = ', '), ' in ', paste(config$years, collapse = ', '))
   if(nrow(transects) == 0)
      stop('No transect data for these classes')
   
   transects <- st_make_valid(transects)                                      # fix any invalid geometries
   transects <- st_buffer(transects, dist = 0)                                # may fix topology issues
   
   if(!is.null(transects$reject))                                             # if there's a reject column,
      transects <- transects[is.na(transects$reject) | 
                                transects$reject == 0, ]                      #    DROP rejected rows
   
   
   invalid_geoms <- !st_is_valid(transects)                                   # remove any remaining invalid geometries
   if (any(invalid_geoms)) {
      message('Removing ', sum(invalid_geoms), ' invalid transect geometries')
      transects <- transects[!invalid_geoms, ]
   }
   
   
   if(config$smooth > 1) {                                                    # ----- smooth training data
      message('   ======= Smoothing with ', config$smooth, 'x', config$smooth, ' moving window =====')
      input_stack <- focal(input_stack, w = matrix(1/config$smooth^2, config$smooth, config$smooth), fun = 'mean', na.rm = TRUE)
   }
   
   
   if(config$upscale > 1) {                                                   # ----- upscale training data
      message('   ======= Upscaling to ', config$upscale, 'x', config$upscale, ' =====')
      input_stack <- aggregate(input_stack, fact = config$upscale, fun = mean)
   }
   
   
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
      message('')
   }
   
   
   message('Data preparation complete!')
}
