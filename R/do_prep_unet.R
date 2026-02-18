#' Pre-process data for U-Net
#' 
#' Creates numpy arrays ready for fitting in U-Net. Result files are placed in `<site>/unet/<model>`.
#' 
#' @param model The model name, which is also the name of a `.yml` parameter file in the `pars` 
#'    directory. This file must contain the following:
#'    - years: the year(s) of field data to fit
#'    - orthos: file names of all orthophotos to include
#'    - patch: size in pixels
#'    - depth: number of of downsampling stages
#'    - classes: vector of target classes
#'    - holdout: holdout set to use (uses bypoly<holdout>, classes 1 and 6). Holdout sets are
#'      created by `gather` to yield at least 20% of separate polys. There are 5 sets to choose from.
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
   
   
   config <- read_yaml(file.path(the$parsdir, paste0(model, '.yml')))
   
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
   
   
   x <- file.path(resolve_dir(the$shapefilesdir, config$site), get_sites(config$site)$transects)
   transect_file <- paste0(file_path_sans_ext(x), '_final.shp')
   output_dir <- file.path(resolve_dir(the$unetdir, config$site), model)
   
   
   # 1. Build input stack
   message('Building input stack...')
   input_stack <- unet_build_input_stack(config)                              # ----- build input stack
   
   
   message('Loading transects...')
   transects <- st_read(transect_file, 
                        promote_to_multi = FALSE, quiet = TRUE)              # ----- read transects
   
   
   names(transects) <- tolower(names(transects))                              # name cases aren't consistent, of course
   
   
   if(config$reclass != '') {                                                 # if reclassifying transects (for multi-stage models),
      classes <- read_pars_table('classes')                                   #    read classes file
      transects$subclass <- 
         classes[match(transects$subclass, classes$subclass), config$reclass] #    and reclassify
      message('Reclassified subclass to ', config$reclass)
   }
   
   
   transects <- transects[transects$subclass %in% config$classes, ]           # filter to target classes
   transects <- transects[transects$year %in% config$years, ]                 # and to years
   message(nrow(transects), ' polys in transects for classes ', paste(config$classes, collapse = ', '), ' in ', paste(config$years, collapse = ', '))
   if(nrow(transects) == 0)
      stop('No transect data for these classes')
   
   transects <- st_make_valid(transects)                                      # fix any invalid geometries
   transects <- st_buffer(transects, dist = 0)                                # may fix topology issues
   
   invalid_geoms <- !st_is_valid(transects)                                   # remove any remaining invalid geometries
   if (any(invalid_geoms)) {
      message('Removing ', sum(invalid_geoms), ' invalid transect geometries')
      transects <- transects[!invalid_geoms, ]
   }
   
   
   message('Creating train/validate/test split...')                           # ----- split into training, validation, and test data
   split <- unet_spatial_train_val_split(
      transects = transects,
      holdout = config$holdout 
   )                                                                          
   
   
   if(config$smooth > 1) {                                                    # ----- smooth training data
      message('======= Smoothing with ', config$smooth, 'x', config$smooth, ' moving window =====')
      input_stack <- focal(input_stack, w = matrix(1/config$smooth^2, config$smooth, config$smooth), fun = 'mean', na.rm = TRUE)
   }
   
   
   if(config$upscale > 1) {                                                   # ----- upscale training data
      message('======= Upscaling to ', config$upscale, 'x', config$upscale, ' =====')
      input_stack <- aggregate(input_stack, fact = config$upscale, fun = mean)
   }
   
   
   message('Extracting patches...')                                           # ----- extract patches
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
   
   
   patch_stats <<- unet_patch_stats(patches)                                  # ----- get and display stats on patches, including purity histogram
   
   
   message('Exporting to numpy...')                                           # ----- export to numpy
   unet_export_to_numpy(
      patches = patches,
      output_dir = output_dir,
      site = config$site, 
      class_mapping = config$class_mapping
   )
   
   
   message('Data preparation complete!')
   
   # return(invisible(list(                                 # this bogs down for some reason
   #    patches = patches,
   #    split_indices = split_indices,
   #    input_stack = input_stack,
   #    transects = transects
   # )))
}
