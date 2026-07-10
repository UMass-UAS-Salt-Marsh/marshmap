#' Build the U-Net input stack and prepared transects
#'
#' Shared setup for `do_unet_prep` and the pixel-degradation experiment
#' (`do_degrade_prep`). Builds the multi-band input stack, reads and cleans the
#' field transects (reclass, class/year filtering, overlap removal, geometry
#' repair), assigns spatially-distributed holdout groups (`bypoly00`), and applies
#' optional smoothing and upscaling. Keeping this in one place guarantees the
#' experiment's train/val/test split is byte-for-byte identical to the production
#' pipeline's.
#'
#' @param config A config list already passed through [unet_config_defaults()].
#' @returns List with `input_stack` (SpatRaster) and `transects` (sf, post
#'   `spatial_holdout`, smoothed/upscaled to match the stack).
#' @importFrom terra rast focal aggregate
#' @importFrom sf st_read st_make_valid st_buffer st_is_valid
#' @keywords internal


unet_prep_setup <- function(config) {


   transect_file <- file.path(resolve_dir(the$shapefilesdir, config$site), paste0(toupper(config$site), '_', config$transects, '.shp'))
   if(!file.exists(transect_file))
      stop('Transects file not found: ', transect_file)


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
   if(!is.null(transects$year))
      transects <- transects[transects$year %in% config$years, ]              # and to years (if column exists)
   transects <- overlaps(transects, 'subclass', all = TRUE)                   # remove overlapping polys, whether or not they agree
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


   message('Assigning spatially distributed holdout sets...')
   transects <- spatial_holdout(transects)                                    # Now assign holdout sequence to bypoly00


   if(config$smooth > 1) {                                                    # ----- smooth training data
      message('   ======= Smoothing with ', config$smooth, 'x', config$smooth, ' moving window =====')
      input_stack <- focal(input_stack, w = matrix(1/config$smooth^2, config$smooth, config$smooth), fun = 'mean', na.rm = TRUE)
   }


   if(config$upscale > 1) {                                                   # ----- upscale training data
      message('   ======= Upscaling to ', config$upscale, 'x', config$upscale, ' =====')
      input_stack <- aggregate(input_stack, fact = config$upscale, fun = mean)
   }


   list(input_stack = input_stack, transects = transects)
}
