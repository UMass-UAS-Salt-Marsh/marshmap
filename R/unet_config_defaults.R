#' Normalize and derive a U-Net model config
#'
#' Fills in defaults and derives helper fields for a U-Net model config (as read
#' from a `<model>.yml` in `<pars>/unet/`). Shared by `do_unet_prep` and the
#' pixel-degradation experiment (`do_degrade_prep`) so both see an identical,
#' fully-populated config.
#'
#' Derives `fpath`, `bands`, `n_channels`, per-ortho `type`, `class_mapping`, and
#' `seed`; supplies defaults for `transects`, `reclass`, `upscale`, `smooth`,
#' `holdout_col`, `cv`, `val`, and `test`; and validates the cross-validation grid.
#'
#' @param config Config list read from a model `.yml`.
#' @returns The enriched config list.
#' @importFrom terra rast nlyr
#' @keywords internal


unet_config_defaults <- function(config) {


   config$fpath <- resolve_dir(the$flightsdir, config$site)
   config$bands <- unlist(lapply(config$orthos, function(x)
      nlyr(rast(file.path(config$fpath, x)))))                                # number of bands for each ortho
   config$n_channels <- sum(config$bands)                                     # total number of channels

   config$type <- rep('image', length(config$orthos))                         # type for each ortho
   config$type[grep('__NDVI', config$orthos)] <- 'ndvi'
   config$type[grep('__NDWIg', config$orthos)] <- 'ndwi'
   config$type[grep('__NDRE', config$orthos)] <- 'ndre'
   config$type[grep('DEM', config$orthos)] <- 'dem'
   config$type[config$type == 'image' & config$bands == 1] <- 'scalar'        # any remaining 1-band layer (mean, sd, etc.)

   config$class_mapping <- as.list(0:(length(config$classes) - 1))            # 0:(n-1) classes for U-Net
   names(config$class_mapping) <- config$classes                              # mapping to our class numbers
   config$seed <- 42                                                          # random seed for repeatability

   if(is.null(config$transects))                                              # default field transects: "transects"
      config$transects <- 'transects'

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

   config
}
