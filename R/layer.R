#' Combine multiple geoTIFF maps into a single integrated layer
#' 
#' Reads a YAML config from `pars/unet/<name>.yml` describing how to layer
#' a base map with one or more fill maps, validates it, and either runs
#' the work locally (for small jobs) or dispatches it to Slurm via 
#' `slurmcollie` (for large jobs). The actual work happens in `do_layer`.
#' 
#' ## YAML config format
#' 
#' ```yaml
#' source: /path/to/maps                # directory holding all input maps
#' result: integrated1                  # output filename stem (no extension)
#' base: map_NOR_1684_all               # base map filename stem
#' fill:                                # optional list of fill rules
#'   - code: 99                         # cells in base with this code...
#'     map: map_NOR_1701_all            # ...are replaced with this map
#'     fill:                            # nested fills (arbitrary depth)
#'       - code: 103
#'         map: map_NOR_1725_all
#'       - code: 104
#'         map: map_NOR_9999_all
#'   - code: 98
#'     map: map_NOR_9998_all
#' allowmissing: false                  # optional, default false. If true,
#'                                      #   missing fill codes are warnings,
#'                                      #   not errors.
#' ```
#'
#' ## Validation
#' 
#' Before any heavy work, `layer()` checks:
#' - Config file exists and parses
#' - Required keys present (source, result, base)
#' - All referenced map files exist on disk
#' - All declared fill codes are in the INT1U range (0-255)
#' - All maps have aligned geometry (extent, resolution, CRS)
#' - Each fill code is actually present in its parent map (this check
#'   happens inline during `do_layer`, since it requires reading raster
#'   values; failure produces a clear error mentioning the offending 
#'   code and map)
#' 
#' Geometry alignment is checked by reading raster *headers* only, not 
#' values, so it's cheap.
#' 
#' ## Local vs. Slurm dispatch
#' 
#' If `slurm = NULL` (default), `layer()` estimates the work from total
#' pixel count across all source maps. Below ~500M pixels, runs locally;
#' above, dispatches to Slurm. Override with `slurm = TRUE` or 
#' `slurm = FALSE`.
#' 
#' @param name (character) base name of the YAML config in `pars/unet/`
#' @param slurm (logical or NULL) `NULL` (default) auto-decides; `TRUE` 
#'   forces Slurm dispatch; `FALSE` forces local execution
#' @param threshold_mpix (numeric) megapixel threshold above which Slurm 
#'   dispatch is preferred when `slurm = NULL`. Default 500.
#' @return Invisibly returns the path to the integrated GeoTIFF (when run
#'   locally), or the slurmcollie job id (when dispatched).
#' @importFrom yaml read_yaml
#' @importFrom terra rast compareGeom ncell
#' @export


layer <- function(name, slurm = NULL, threshold_mpix = 500) {
   
   pars_file <- file.path(the$parsdir, 'unet', paste0(name, '.yml'))
   if(!file.exists(pars_file))
      stop('config file not found: ', pars_file)
   
   cfg <- read_yaml(pars_file)
   
   # --- structural validation ---
   for(key in c('source', 'result', 'base')) {
      if(is.null(cfg[[key]]))
         stop('config missing required key: ', key)
   }
   
   if(!dir.exists(cfg$source))
      stop('source directory does not exist: ', cfg$source)
   
   # Walk the fill tree, collect all map names + fill codes
   all_maps <- cfg$base
   all_codes <- integer(0)
   collect <- function(rules) {
      for(rule in rules) {
         if(is.null(rule$code) || is.null(rule$map))
            stop('every fill rule must have `code` and `map`')
         all_maps <<- c(all_maps, rule$map)
         all_codes <<- c(all_codes, as.integer(rule$code))
         if(!is.null(rule$fill))
            collect(rule$fill)
      }
   }
   if(!is.null(cfg$fill))
      collect(cfg$fill)
   
   # --- file existence ---
   for(m in all_maps) {
      p <- file.path(cfg$source, paste0(m, '.tif'))
      if(!file.exists(p))
         stop('source map not found: ', p)
   }
   
   # --- fill-code range check ---
   bad <- all_codes[all_codes < 0 | all_codes > 255]
   if(length(bad) > 0)
      stop('fill codes outside INT1U range (0-255): ', 
           paste(unique(bad), collapse = ', '))
   
   # --- geometry alignment (header reads only) ---
   message('Validating geometry alignment...')
   base_path <- file.path(cfg$source, paste0(cfg$base, '.tif'))
   base_r <- rast(base_path)
   total_cells <- ncell(base_r)                                                # for size estimation below
   
   for(m in setdiff(all_maps, cfg$base)) {
      p <- file.path(cfg$source, paste0(m, '.tif'))
      r <- rast(p)
      if(!compareGeom(base_r, r, stopOnError = FALSE))
         stop('geometry mismatch: ', m, ' does not align with base map ',
              cfg$base, '. Check extent/resolution/CRS.')
   }
   
   # --- dispatch ---
   total_mpix <- (total_cells * length(all_maps)) / 1e6                        # rough work estimate
   
   if(is.null(slurm))
      slurm <- total_mpix > threshold_mpix
   
   if(slurm) {
      message(sprintf('Dispatching to Slurm (estimated %.0f Mpix work, ',
                      total_mpix), 
              'threshold ', threshold_mpix, ')')
      # Adjust this call to match your slurmcollie conventions; the pattern 
      # below mirrors how do_map etc. are dispatched in the codebase.
      jobid <- slurmcollie::slurm('do_layer', moreargs = list(name = name), 
                                  reps = 1, jobname = paste0('layer_', name))
      invisible(jobid)
   } else {
      message(sprintf('Running locally (estimated %.0f Mpix work, ', 
                      total_mpix),
              'threshold ', threshold_mpix, ')')
      do_layer(name)
   }
}
