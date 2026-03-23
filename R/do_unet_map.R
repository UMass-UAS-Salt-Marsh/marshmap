#' Map with a trained U-Net model (worker)
#'
#' Orchestrates the full mapping pipeline: prep patches, predict with GPU,
#' assemble into GeoTIFF. Typically called as a batch job by `unet_map()` or
#' dispatched from `map()`.
#'
#' @param model The model name (base name of the prep `.yml`)
#' @param result The training result subdirectory (e.g., `'fit01'`)
#' @param which Which model(s) to use: `'all'`, `'full'`, or integer 1-5
#' @param clip Optional clip extent
#' @param write_probs If TRUE, write probability layers
#' @param mapid Map database id (if called from `map()`)
#' @param fitid Fit database id (for reference / logging)
#' @param rep Throwaway argument for slurmcollie
#' @importFrom yaml read_yaml
#' @importFrom reticulate source_python
#' @export


do_unet_map <- function(model, result = 'fit01', which = 'all', clip = NULL,
                        write_probs = FALSE, mapid = NULL, fitid = NULL, 
                        rep = NULL) {
   
   
   config <- read_yaml(file.path(the$parsdir, 'unet', paste0(model, '.yml')))
   site <- config$site
   model_dir <- file.path(resolve_dir(the$unetdir, site), model)
   fit_dir <- file.path(model_dir, result)
   
   
   # ── Step 1: Prep map patches ───────────────────────────────────────────────
   message('\n=== STEP 1: Preparing map patches ===')
   do_unet_prep_map(model = model, clip = clip)                                # skips if already done
   
   # Determine patches directory
   if(!is.null(clip)) {
      clip_tag <- paste0('clip_', round(extent_area(clip)), '_ha')             # TODO: verify extent_area
      patches_dir <- file.path(model_dir, paste0('map_patches_', clip_tag))
   }
   else {
      patches_dir <- file.path(model_dir, 'map_patches')
   }
   
   
   # ── Step 2: Resolve model weights ──────────────────────────────────────────
   site_upper <- toupper(site)
   
   if(is.numeric(which)) {
      # Single CV fold
      weights <- file.path(fit_dir, paste0('set', which), 
                           paste0('unet_', site_upper, '_final.pth'))
      config_json <- file.path(fit_dir, paste0('set', which),
                               paste0('unet_', site_upper, '_config.json'))
      if(!file.exists(weights))
         stop('Model weights not found: ', weights)
      message('Using CV fold ', which)
   }
   else if(identical(which, 'full')) {
      # Full model (trained on all data)
      weights <- file.path(fit_dir, 'full',
                           paste0('unet_', site_upper, '_final.pth'))
      config_json <- file.path(fit_dir, 'full',
                               paste0('unet_', site_upper, '_config.json'))
      if(!file.exists(weights))
         stop('Full model not found: ', weights)
      message('Using full model (trained on all data)')
   }
   else {
      # 'all': ensemble of all CV folds
      cv <- config$cv
      weights <- character(cv)
      for(i in seq_len(cv)) {
         weights[i] <- file.path(fit_dir, paste0('set', i),
                                 paste0('unet_', site_upper, '_final.pth'))
         if(!file.exists(weights[i]))
            stop('CV fold ', i, ' weights not found: ', weights[i])
      }
      # Use config from set1 (architecture is identical across folds)
      config_json <- file.path(fit_dir, 'set1',
                               paste0('unet_', site_upper, '_config.json'))
      message('Using ensemble of ', cv, ' CV models')
   }
   
   if(!file.exists(config_json))
      stop('Model config not found: ', config_json)
   
   
   # ── Step 3: Predict ────────────────────────────────────────────────────────
   message('\n=== STEP 2: Predicting (GPU) ===')
   
   python_script <- system.file('python', 'predict_unet_map.py', package = 'marshmap')
   if(!file.exists(python_script))
      stop('predict_unet_map.py not found in inst/python/')
   
   source_python(python_script)
   
   predict_unet_map(
      patches_dir = patches_dir,
      model_weights = weights,                                                 # single path or vector of paths
      config_path = config_json,
      batch_size = 64L
   )
   
   
   # ── Step 4: Assemble ───────────────────────────────────────────────────────
   message('\n=== STEP 3: Assembling map ===')
   
   # Build output filename: map_<site>_<fitid>_[clip_<area>_ha].tif
   maps_dir <- resolve_dir(the$mapsdir, site)
   
   which_tag <- if(is.numeric(which)) paste0('cv', which) 
                else which
   
   fname_parts <- c('map', tolower(site))
   if(!is.null(fitid))
      fname_parts <- c(fname_parts, fitid)
   fname_parts <- c(fname_parts, which_tag)
   if(!is.null(clip)) {
      clip_tag <- paste0('clip_', round(extent_area(clip)), '_ha')
      fname_parts <- c(fname_parts, clip_tag)
   }
   
   output_file <- file.path(maps_dir, paste0(paste(fname_parts, collapse = '_'), '.tif'))
   
   message(sprintf('Fitid: %s, model: %s, result: %s, which: %s',
                   ifelse(is.null(fitid), 'none', fitid), model, result, which))
   
   
   result_info <- unet_assemble_map(
      patches_dir = patches_dir,
      output_file = output_file,
      config = config,
      write_probs = write_probs
   )
   
   
   # ── Save temp results for map_finish ───────────────────────────────────────
   if(!is.null(mapid)) {
      saveRDS(list(mpix = result_info$mpix, fitid = fitid),
              file.path(maps_dir, paste0('zz_', mapid, '_map.RDS')))
   }
   
   
   message('\n=== Mapping complete ===')
   message('Fitid: ', ifelse(is.null(fitid), 'none', fitid))
   message('Output: ', output_file)
}
