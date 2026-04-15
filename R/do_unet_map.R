#' Map with a trained U-Net model (worker)
#'
#' Orchestrates the full mapping pipeline: prep patches, predict with GPU,
#' assemble into GeoTIFF. Called as a batch job by `map()` when the fit
#' method is `'unet'`.
#'
#' @param model The model name (base name of the prep `.yml`)
#' @param site Three letter site code
#' @param fit_result The training result subdirectory (e.g., `'fit01'`)
#' @param result Output filename base (without `.tif`), from `map()`
#' @param which Which model(s) to use: `'all'`, `'full'`, or integer 1-5
#' @param clip Optional clip extent
#' @param write_probs If TRUE, write probability layers
#' @param mapid Map database id
#' @param fitid Fit database id (for reference / logging)
#' @param requirecuda If TRUE (default), abort immediately if CUDA is not available rather than
#'    silently falling back to CPU. Set to FALSE only for testing without a GPU.
#' @param rep Throwaway argument for slurmcollie
#' @importFrom yaml read_yaml
#' @importFrom reticulate source_python
#' @importFrom terra rast crs
#' @export


do_unet_map <- function(model, site, fit_result = 'fit01', result,
                        which = 'all', clip = NULL,
                        write_probs = FALSE, mapid = NULL, fitid = NULL,
                        requirecuda = TRUE, rep = NULL) {

   
   cuda_check(requirecuda)                                                          # make sure CUDA is available
   
   
   config <- read_yaml(file.path(the$parsdir, 'unet', paste0(model, '.yml')))
   if(is.null(config$cv)) config$cv <- 5
   model_dir <- file.path(resolve_dir(the$unetdir, site), model)
   fit_dir <- file.path(model_dir, fit_result)


   # ── Step 1: Prep map patches ───────────────────────────────────────────────
   message('\n=== STEP 1: Preparing map patches ===')
   do_unet_prep_map(model = model, clip = clip)                                # skips if already done

   # Determine patches directory
   if(!is.null(clip)) {
      site_crs <- crs(rast(file.path(resolve_dir(the$flightsdir, site),
                                     config$orthos[1])))
      clip_tag <- paste0('clip_', round(extent_area(clip, crs = site_crs)), '_ha')
      patches_dir <- file.path(model_dir, paste0('map_patches_', clip_tag))
   }
   else {
      patches_dir <- file.path(model_dir, 'map_patches')
   }


   gc()                                                                          # release R heap before Python loads patches

   # ── Step 2: Resolve model weights ──────────────────────────────────────────
   site_upper <- toupper(site)

   if(is.numeric(which)) {
      # Single CV fold
      weights <- file.path(fit_dir, paste0('set', which),
                           paste0('unet_', site_upper, '_final.pth'))
      if(!file.exists(weights))
         stop('Model weights not found: ', weights)
      message('Using CV fold ', which)
   }
   else if(identical(which, 'full')) {
      # Full model (trained on all data)
      weights <- file.path(fit_dir, 'full',
                           paste0('unet_', site_upper, '_final.pth'))
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
      message('Using ensemble of ', cv, ' CV models')
   }

   # Config is at fit level (architecture is identical across folds)
   config_json <- file.path(fit_dir, paste0('unet_', site_upper, '_config.json'))
   if(!file.exists(config_json))
      stop('Model config not found: ', config_json)


   # ── Step 3: Predict ────────────────────────────────────────────────────────
   message('\n=== STEP 3: Predicting (GPU) ===')

   python_script <- system.file('python', 'predict_unet_map.py', package = 'marshmap')
   if(!file.exists(python_script))
      stop('predict_unet_map.py not found in inst/python/')

   source_python(python_script)

   predict_unet_map(
      patches_dir = patches_dir,
      model_weights = weights,                                                 # single path or vector of paths
      config_path = config_json,
      batch_size = 64L,
      requirecuda = requirecuda
   )


   # ── Step 4: Assemble ───────────────────────────────────────────────────────
   message('\n=== STEP 4: Assembling map ===')

   maps_dir <- resolve_dir(the$mapsdir, site)
   output_file <- file.path(maps_dir, paste0(result, '.tif'))

   message(sprintf('Fitid: %s, model: %s, fit_result: %s, which: %s',
                   ifelse(is.null(fitid), 'none', fitid), model, fit_result, which))


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
