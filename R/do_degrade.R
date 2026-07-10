#' Train and evaluate one cell of the pixel-degradation experiment
#'
#' Per-cell worker for [degrade()] (stage `'train'`). Trains the U-Net on the carved
#' patches for one fold x radius (prepared by [do_degrade_prep()]) with a given random
#' seed, evaluates on the fold's full-extent test set, and writes one tidy result row.
#' A radius of `Inf` is the full-transect anchor.
#'
#' Reads patches from `<unetdir>/<model>/degrade/f<test>/r<NNN>/patches/set1/`, writes
#' the fit to `.../f<test>/r<NNN>/s<seed>/set1/`, and appends a per-cell result file
#' `.../degrade/cell_f<test>_r<NNN>_s<seed>.csv`. Each cell writes its own file to avoid
#' concurrent-write races across the Slurm array.
#'
#' @param rep Row index into `grid` (supplied by slurmcollie).
#' @param grid data.frame with `radius`, `seed`, `test`, `val` columns (fold x radius x seed).
#' @param exp Experiment YAML base name in `<pars>/unet/`.
#' @param model Model YAML base name in `<pars>/unet/`.
#' @param train Training YAML base name in `<pars>/unet/`, or NULL.
#' @param requirecuda If TRUE (default), abort if CUDA is unavailable.
#' @param pin_weights If TRUE, train with class weights pinned to the fold's
#'   full-transect frequency (read from `f<test>/class_weights_pinned.json`).
#' @import reticulate
#' @importFrom jsonlite read_json
#' @export


do_degrade <- function(rep, grid, exp, model, train, requirecuda = TRUE, pin_weights = FALSE) {


   radius <- grid$radius[rep]
   seed   <- grid$seed[rep]
   test   <- grid$test[rep]
   val    <- grid$val[rep]
   anchor <- is.infinite(radius)
   message('======== degrade train: fold test/val ', test, '/', val, ', radius ',
           if(anchor) 'FULL (anchor)' else paste0(radius, ' m'), ', seed ', seed, ' ========')

   cuda_check(requirecuda)

   config <- read_degrade_config(model, train, exp)

   fold_dir   <- degrade_fold_dir(config, model, test)
   rtag       <- degrade_rtag(radius)
   radius_dir <- file.path(fold_dir, rtag)
   data_dir   <- file.path(radius_dir, 'patches', paste0('set', 1))
   output_dir <- file.path(radius_dir, paste0('s', seed), 'set1')

   if(!dir.exists(data_dir))
      stop('carved patches not found at ', data_dir, '; run degrade(stage = "prep") first')


   # Pinned class weights (fold-level, from full transects) if requested.
   class_weights <- NULL
   if(pin_weights) {
      pinned_file <- file.path(fold_dir, 'class_weights_pinned.json')
      if(!file.exists(pinned_file))
         stop('pin_weights = TRUE but ', pinned_file, ' not found; re-run degrade(stage = "prep")')
      pw <- jsonlite::read_json(pinned_file, simplifyVector = TRUE)
      class_weights <- as.numeric(pw$class_weights)
      message('   Pinned class weights: ',
              paste(sprintf('%d=%.3f', pw$original_classes, class_weights), collapse = ', '))
   }


   # Source the Python training script (dev tree or installed package).
   py <- system.file('python', 'train_unet.py', package = 'marshmap')
   if(py == '') py <- 'inst/python/train_unet.py'
   message('Sourcing Python code & initializing...')
   reticulate::source_python(py)


   # Train. class_weights (if pinned) overrides class_weighting inside Python.
   # seed varies network init + data order.
   train_unet(
      site                   = config$site,
      data_dir               = data_dir,
      output_dir             = output_dir,
      use_ordinal            = config$use_ordinal,
      original_classes       = as.integer(config$classes),
      num_classes            = length(config$classes),
      encoder_name           = config$encoder_name,
      encoder_weights        = config$encoder_weights,
      learning_rate          = config$learning_rate,
      weight_decay           = config$weight_decay,
      class_weighting        = config$class_weighting,
      class_weights          = class_weights,
      n_epochs               = as.integer(config$n_epochs),
      batch_size             = as.integer(config$batch_size),
      gradient_clip_max_norm = config$gradient_clip_max_norm,
      test_interval          = as.integer(if(!is.null(config$test_interval)) config$test_interval else 1L),
      requirecuda            = requirecuda,
      seed                   = as.integer(seed))


   # Evaluate on the fold's full-extent test set.
   message('Predicting on test set...')
   model_file <- file.path(output_dir, paste0('unet_', toupper(config$site), '_final.pth'))
   pred       <- unet_predict(model_file, data_dir, config$site, dataset = 'test')
   cm         <- unet_confusion_matrix(pred)

   ccr   <- as.numeric(cm$overall['Accuracy'])
   kappa <- as.numeric(cm$overall['Kappa'])

   bc     <- cm$byClass                                                       # per-class recall (prec_recall mode)
   recall <- if(is.matrix(bc)) bc[, 'Recall'] else bc['Recall']
   recall_names <- if(is.matrix(bc)) sub('^Class: ', '', rownames(bc)) else sub('^Class: ', '', names(bc)[1])
   names(recall) <- paste0('recall_', recall_names)


   # Metadata from prep + logged class weights.
   meta <- readRDS(file.path(radius_dir, 'degrade_meta.rds'))
   weights_str <- ''
   wf <- file.path(output_dir, 'class_weights.json')
   if(file.exists(wf)) {
      w <- jsonlite::read_json(wf, simplifyVector = TRUE)
      weights_str <- paste(sprintf('%s=%.3f', w$original_classes, w$class_weights), collapse = ', ')
   }


   row <- data.frame(
      radius_m    = radius,
      radius_px   = meta$radius_px,
      px_per_plot = meta$px_per_plot_geom,
      n_plots     = meta$n_plots,
      seed        = seed,
      model       = model,
      test_group  = paste(test, collapse = ','),
      val_group   = paste(val,  collapse = ','),
      ccr         = ccr,
      kappa       = kappa,
      weighting   = if(pin_weights) 'pinned' else config$class_weighting,
      weights_str = weights_str,
      timestamp   = format(Sys.time(), '%Y-%m-%d %H:%M:%S'),
      stringsAsFactors = FALSE)
   row <- cbind(row, as.data.frame(as.list(recall)))                          # recall_<class> columns

   result_file <- file.path(degrade_dir(config, model),
                            sprintf('cell_%s_%s_s%d.csv', degrade_fold_tag(test), rtag, seed))
   write.csv(row, result_file, row.names = FALSE)

   message(sprintf('degrade cell done: fold %s/%s, r=%s, seed=%d, CCR=%.1f%%, kappa=%.2f -> %s',
                   test, val, if(anchor) 'FULL' else sprintf('%.2f m', radius),
                   seed, ccr * 100, kappa, result_file))
   invisible(row)
}
