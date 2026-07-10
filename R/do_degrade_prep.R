#' Prepare carved training patches for one fold x radius of the degradation experiment
#'
#' Per-cell prep worker for [degrade()] (stage `'prep'`). For one spatial fold (a
#' test/val group pair) and one plot radius, it builds the input stack and prepared
#' transects via the shared [unet_prep_setup()], makes the fold's fixed 3-way spatial
#' split, carves the TRAINING transects to radius-`r` disks around fixed synthetic plot
#' centers (validation/test stay full extent), extracts patches, and exports numpy
#' arrays. A radius of `Inf` is the full-transect ANCHOR: training transects are used
#' uncarved. Centers are computed from the fold's training extent and are therefore
#' identical across radii and seeds within a fold.
#'
#' Writes patches to `<unetdir>/<model>/degrade/f<test>/r<NNN>/patches/set1/` (where
#' `NNN = round(radius * 100)`, or `rfull` for the anchor) plus a `degrade_meta.rds`
#' marker, and — once per fold — the pinned class weights `f<test>/class_weights_pinned.json`
#' computed from the fold's full (uncarved) training transects.
#'
#' @param rep Row index into `pgrid` (supplied by slurmcollie).
#' @param pgrid data.frame with `radius`, `test`, `val` columns (the fold x radius grid).
#' @param exp Experiment YAML base name in `<pars>/unet/`.
#' @param model Model YAML base name in `<pars>/unet/`.
#' @param train Training YAML base name in `<pars>/unet/`, or NULL.
#' @param save_gis If TRUE, save plot centers, clipped disks, and training polys as
#'   GeoPackages under `f<test>/r<NNN>/gis/` for inspection.
#' @importFrom terra res
#' @importFrom jsonlite write_json
#' @export


do_degrade_prep <- function(rep, pgrid, exp, model, train, save_gis = FALSE) {


   radius <- pgrid$radius[rep]
   test   <- pgrid$test[rep]
   val    <- pgrid$val[rep]
   anchor <- is.infinite(radius)
   message('======== degrade prep: fold test/val ', test, '/', val,
           ', radius ', if(anchor) 'FULL (anchor)' else paste0(radius, ' m'), ' ========')

   config <- read_degrade_config(model, train, exp)

   setup       <- unet_prep_setup(config)                                     # shared with do_unet_prep: input stack + prepared transects
   input_stack <- setup$input_stack
   transects   <- setup$transects
   pixel_m     <- terra::res(input_stack)[1]


   # The fold's fixed 3-way spatial split: this fold's test/val groups held out at
   # full extent, the rest training. cv = 1 so groups are not incremented.
   split <- unet_spatial_train_val_split(
      transects   = transects,
      holdout_col = config$holdout_col,
      cv          = 1,
      val         = val,
      test         = test)


   fold_dir   <- degrade_fold_dir(config, model, test)
   rtag       <- degrade_rtag(radius)
   radius_dir <- file.path(fold_dir, rtag)


   # Pinned class weights for this fold (once): from the full uncarved training
   # transects, so every radius in the fold shares the same loss weighting. Written
   # atomically (temp + rename) so parallel prep jobs in the same fold can't tear it.
   pinned_file <- file.path(fold_dir, 'class_weights_pinned.json')
   if(!file.exists(pinned_file)) {
      dir.create(fold_dir, recursive = TRUE, showWarnings = FALSE)
      pw  <- degrade_pinned_weights(input_stack, transects, split$train_ids, config)
      tmp <- tempfile(tmpdir = fold_dir, fileext = '.json')
      jsonlite::write_json(pw, tmp, auto_unbox = TRUE, digits = 10)
      file.rename(tmp, pinned_file)
      message('   Pinned class weights (full-transect freq): ',
              paste(sprintf('%d=%.3f', pw$original_classes, pw$class_weights), collapse = ', '))
   }


   # Carve TRAINING transects to radius-r disks (clipped to source), or use them
   # uncarved for the full-transect anchor. Centers are radius-independent; end_margin
   # keyed to the experiment's max FINITE radius so centers match across all radii.
   if(anchor) {

      plots <- NULL
      disks <- transects[transects$poly %in% split$train_ids, c('subclass', 'poly')]
      message('   Full-transect anchor: ', nrow(disks), ' training transects, uncarved')

   } else {

      finite_radii <- pgrid$radius[is.finite(pgrid$radius)]
      end_margin   <- max(if(!is.null(config$radii)) config$radii else finite_radii)
      plots <- make_synthetic_plots(transects, split$train_ids,
                                    spacing_m = config$spacing_m, end_margin_m = end_margin)
      disks <- carve_train_transects(plots, transects, radius)
      message('   ', nrow(plots), ' synthetic plots; carved to radius ', radius, ' m (clipped to source transects)')
   }

   comb <- degrade_combined_transects(transects, disks, split$validate_ids, split$test_ids)


   if(save_gis) {                                                             # dump centers (if any), clipped disks, and training polys for QGIS
      gis_dir <- file.path(radius_dir, 'gis')
      dir.create(gis_dir, recursive = TRUE, showWarnings = FALSE)
      train_polys <- transects[transects$poly %in% split$train_ids, c('subclass', 'poly')]
      if(!is.null(plots))
         sf::st_write(plots, file.path(gis_dir, 'plot_centers.gpkg'), delete_dsn = TRUE, quiet = TRUE)
      sf::st_write(disks,       file.path(gis_dir, 'plot_disks.gpkg'), delete_dsn = TRUE, quiet = TRUE)
      sf::st_write(train_polys, file.path(gis_dir, 'train_polys.gpkg'), delete_dsn = TRUE, quiet = TRUE)
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


   output_dir <- file.path(radius_dir, 'patches')                            # unet_export_to_numpy appends /set1

   message('   Exporting to numpy...')
   unet_export_to_numpy(
      patches       = patches,
      output_dir    = output_dir,
      site          = config$site,
      class_mapping = config$class_mapping,
      set           = 1)


   # Marker for do_degrade: plot count, pixel size, and realized training pixels.
   dir.create(radius_dir, recursive = TRUE, showWarnings = FALSE)
   saveRDS(list(
      radius_m            = radius,
      test_group          = test,
      val_group           = val,
      pixel_m             = pixel_m,
      n_plots             = if(anchor) nrow(disks) else nrow(plots),
      radius_px           = if(anchor) NA_real_ else round(radius / pixel_m, 2),
      px_per_plot_geom    = if(anchor) NA_real_ else round(pi * (radius / pixel_m)^2),
      train_pixels_actual = sum(patches$train_masks)
   ), file.path(radius_dir, 'degrade_meta.rds'))

   message('degrade prep complete for fold ', test, '/', val, ', radius ',
           if(anchor) 'FULL' else paste0(radius, ' m'))
}
