#' Subsample sites, train, and evaluate one cell of the site-count experiment
#'
#' Per-cell worker for [degrade_count()]. For one spatial fold (a test/val group pair),
#' one requested site count, and one seed, it builds the input stack and prepared
#' transects via [unet_prep_setup()], makes the fold's fixed 3-way spatial split, draws
#' a random subset of the fold's TRAINING transects (resampled per seed, nested within
#' a seed), places synthetic plots on those transects' centerlines, carves them to the
#' fixed radius, extracts + exports patches, trains the U-Net, evaluates on the fold's
#' full-extent test set, and writes one tidy result row. A count of `Inf` is the
#' all-sites anchor (every training transect). Single-stage: because the subset depends
#' on the seed, carving is seed-specific and cannot be shared across cells.
#'
#' Reads/writes under `<unetdir>/<model>/degrade/f<test>/count/c<NNN|all>/s<seed>/`
#' (`patches/set1/` for exports, `fit/set1/` for the model) and appends a per-cell row
#' `.../degrade/countcell_f<test>_c<NNN>_s<seed>.csv`. Each cell writes its own file to
#' avoid concurrent-write races across the Slurm array. The fold's pinned class weights
#' (`f<test>/class_weights_pinned.json`, from the full training transects) are reused if
#' present and computed atomically if not.
#'
#' @param rep Row index into `grid` (supplied by slurmcollie).
#' @param grid data.frame with `count`, `seed`, `test`, `val` columns (fold x count x seed).
#' @param exp Experiment YAML base name in `<pars>/unet/`.
#' @param model Model YAML base name in `<pars>/unet/`.
#' @param train Training YAML base name in `<pars>/unet/`, or NULL.
#' @param radius Fixed plot radius (m) applied to every cell.
#' @param requirecuda If TRUE (default), abort if CUDA is unavailable.
#' @param pin_weights If TRUE, train with class weights pinned to the fold's
#'   full-transect frequency (read/computed from `f<test>/class_weights_pinned.json`).
#' @param save_gis If TRUE, save plot centers, carved disks, and sampled training polys
#'   as GeoPackages under the cell's `gis/` for inspection.
#' @import reticulate
#' @importFrom jsonlite read_json write_json
#' @importFrom terra res
#' @export


do_degrade_count <- function(rep, grid, exp, model, train, radius = 0.5,
                             requirecuda = TRUE, pin_weights = FALSE, save_gis = FALSE) {


   count  <- grid$count[rep]
   seed   <- grid$seed[rep]
   test   <- grid$test[rep]
   val    <- grid$val[rep]
   anchor <- is.infinite(count)
   message('======== degrade count: fold test/val ', test, '/', val, ', sites ',
           if(anchor) 'ALL (anchor)' else count, ', radius ', radius, ' m, seed ', seed, ' ========')

   cuda_check(requirecuda)

   config <- read_degrade_config(model, train, exp)

   setup       <- unet_prep_setup(config)                                     # shared with do_unet_prep: input stack + prepared transects
   input_stack <- setup$input_stack
   transects   <- setup$transects


   # The fold's fixed 3-way spatial split: this fold's test/val groups held out at
   # full extent, the rest training. cv = 1 so groups are not incremented.
   split <- unet_spatial_train_val_split(
      transects   = transects,
      holdout_col = config$holdout_col,
      cv          = 1,
      val         = val,
      test         = test)


   fold_dir <- degrade_fold_dir(config, model, test)
   ctag     <- degrade_ctag(count)
   cell_dir <- file.path(fold_dir, 'count', ctag, paste0('s', seed))
   data_dir   <- file.path(cell_dir, 'patches', paste0('set', 1))            # unet_export_to_numpy appends /set1
   output_dir <- file.path(cell_dir, 'fit', 'set1')


   # Pinned class weights for this fold (once, from the full uncarved training transects
   # so the loss objective is identical across counts + seeds). Reused if present; else
   # computed and written atomically (temp + rename) so parallel cells can't tear it.
   class_weights <- NULL
   if(pin_weights) {
      pinned_file <- file.path(fold_dir, 'class_weights_pinned.json')
      if(!file.exists(pinned_file)) {
         dir.create(fold_dir, recursive = TRUE, showWarnings = FALSE)
         pw  <- degrade_pinned_weights(input_stack, transects, split$train_ids, config)
         tmp <- tempfile(tmpdir = fold_dir, fileext = '.json')
         jsonlite::write_json(pw, tmp, auto_unbox = TRUE, digits = 10)
         file.rename(tmp, pinned_file)
      }
      pw <- jsonlite::read_json(pinned_file, simplifyVector = TRUE)
      class_weights <- as.numeric(pw$class_weights)
      message('   Pinned class weights: ',
              paste(sprintf('%d=%.3f', pw$original_classes, class_weights), collapse = ', '))
   }


   # Subsample the training TRANSECTS (the independent sampling unit). Resample per seed:
   # a fresh permutation seeded by `seed`, taking the first `count` -> lower counts are
   # nested subsets of higher counts within a seed. count = Inf uses every training site.
   train_ids <- split$train_ids
   if(anchor) {
      site_ids <- train_ids
   } else {
      set.seed(seed)
      perm     <- train_ids[sample.int(length(train_ids))]                   # base sample.int (marshmap masks base::sample); safe for length 1
      site_ids <- perm[seq_len(min(count, length(train_ids)))]
   }
   n_sites <- length(site_ids)
   message('   ', n_sites, ' training sites',
           if(anchor) ' (all)' else paste0(' of ', length(train_ids), ' (requested ', count, ')'))


   # Synthetic plots on the sampled sites' centerlines, carved to the FIXED radius.
   # end_margin keyed to the fixed radius so disks are not clipped at transect ends.
   plots <- make_synthetic_plots(transects, site_ids,
                                 spacing_m = config$spacing_m, end_margin_m = radius)
   disks <- carve_train_transects(plots, transects, radius)
   message('   ', nrow(plots), ' synthetic plots; carved to radius ', radius, ' m (clipped to source transects)')

   comb <- degrade_combined_transects(transects, disks, split$validate_ids, split$test_ids)


   if(save_gis) {                                                             # dump centers, carved disks, and sampled polys for QGIS
      gis_dir <- file.path(cell_dir, 'gis')
      dir.create(gis_dir, recursive = TRUE, showWarnings = FALSE)
      train_polys <- transects[transects$poly %in% site_ids, c('subclass', 'poly')]
      sf::st_write(plots,       file.path(gis_dir, 'plot_centers.gpkg'), delete_dsn = TRUE, quiet = TRUE)
      sf::st_write(disks,       file.path(gis_dir, 'plot_disks.gpkg'),   delete_dsn = TRUE, quiet = TRUE)
      sf::st_write(train_polys, file.path(gis_dir, 'train_polys.gpkg'),  delete_dsn = TRUE, quiet = TRUE)
      message('   Saved GIS layers to ', gis_dir)
   }


   message('   Extracting patches...')
   patches <- unet_extract_training_patches(
      input_stack   = input_stack,
      transects     = comb$transects,
      train_ids     = comb$train_ids,
      validate_ids  = comb$validate_ids,
      test_ids      = comb$test_ids,
      patch         = config$patch,
      overlap       = config$overlap,
      classes       = config$classes,
      class_mapping = config$class_mapping)

   unet_patch_stats(patches)


   message('   Exporting to numpy...')
   unet_export_to_numpy(
      patches       = patches,
      output_dir    = file.path(cell_dir, 'patches'),
      site          = config$site,
      class_mapping = config$class_mapping,
      set           = 1)


   # Source the Python training script (dev tree or installed package).
   py <- system.file('python', 'train_unet.py', package = 'marshmap')
   if(py == '') py <- 'inst/python/train_unet.py'
   message('Sourcing Python code & initializing...')
   reticulate::source_python(py)


   # Train. class_weights (if pinned) overrides class_weighting inside Python.
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


   row <- data.frame(
      count_req        = count,                                              # Inf = all-sites anchor
      n_sites          = n_sites,
      n_plots          = nrow(plots),
      n_train_patches  = sum(patches$has_train),                             # training patches actually used
      train_px         = sum(patches$train_masks),                          # labeled training pixels
      radius_m         = radius,
      n_subclass_train = length(unique(disks$subclass)),                    # classes present after subsampling
      seed             = seed,
      model            = model,
      test_group       = paste(test, collapse = ','),
      val_group        = paste(val,  collapse = ','),
      ccr              = ccr,
      kappa            = kappa,
      weighting        = if(pin_weights) 'pinned' else config$class_weighting,
      timestamp        = format(Sys.time(), '%Y-%m-%d %H:%M:%S'),
      stringsAsFactors = FALSE)
   row <- cbind(row, as.data.frame(as.list(recall)))                         # recall_<class> columns

   result_file <- file.path(degrade_dir(config, model),
                            sprintf('countcell_%s_%s_s%d.csv', degrade_fold_tag(test), ctag, seed))
   write.csv(row, result_file, row.names = FALSE)

   message(sprintf('degrade count cell done: fold %s/%s, sites=%s (%d), seed=%d, CCR=%.1f%%, kappa=%.2f -> %s',
                   test, val, if(anchor) 'ALL' else as.character(count), n_sites,
                   seed, ccr * 100, kappa, result_file))
   invisible(row)
}
