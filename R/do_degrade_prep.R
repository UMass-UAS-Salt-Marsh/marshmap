#' Prepare carved training patches for one radius of the degradation experiment
#'
#' Per-radius worker for [degrade()] (stage `'prep'`). Builds the input stack and
#' prepared transects via the shared [unet_prep_setup()], makes one fixed 3-way
#' spatial split, carves the TRAINING transects to radius-`r` disks around fixed
#' synthetic plot centers (validation/test stay full extent), extracts patches, and
#' exports numpy arrays. Centers are computed from the training extent and are
#' therefore identical across radii and seeds.
#'
#' Writes patches to `<unetdir>/<model>/degrade/r<NNN>/patches/set1/` (where
#' `NNN = round(radius * 100)`) plus a `degrade_meta.rds` marker with plot count,
#' pixel size, and the realized training-pixel count.
#'
#' @param rep Index into `radii` (supplied by slurmcollie).
#' @param radii Numeric vector of plot radii (m); this job handles `radii[rep]`.
#' @param exp Experiment YAML base name in `<pars>/unet/`.
#' @param model Model YAML base name in `<pars>/unet/`.
#' @param train Training YAML base name in `<pars>/unet/`, or NULL.
#' @param save_gis If TRUE, save plot centers, clipped disks, and training polys as
#'   GeoPackages under `r<NNN>/gis/` for inspection.
#' @importFrom terra res
#' @export


do_degrade_prep <- function(rep, radii, exp, model, train, save_gis = FALSE) {


   radius <- radii[rep]
   message('======== degrade prep: radius ', radius, ' m ========')

   config <- read_degrade_config(model, train, exp)

   setup       <- unet_prep_setup(config)                                     # shared with do_unet_prep: input stack + prepared transects
   input_stack <- setup$input_stack
   transects   <- setup$transects
   pixel_m     <- terra::res(input_stack)[1]


   # One fixed 3-way spatial split (phase 1): test_group / val_group held out at
   # full extent, the rest training. cv = 1 so groups are not incremented.
   split <- unet_spatial_train_val_split(
      transects   = transects,
      holdout_col = config$holdout_col,
      cv          = 1,
      val         = config$val_group,
      test         = config$test_group)


   rtag       <- sprintf('r%03d', round(radius * 100))
   radius_dir <- file.path(degrade_dir(config, model), rtag)

   # Fixed synthetic plot centers on transect centerlines (radius-independent), then
   # carve to radius-r disks clipped to each center's source transect -- no labels
   # fabricated outside the digitized ground truth. end_margin = the experiment's max
   # radius (from the YAML, not this job's subset) so centers are identical across all
   # prep jobs and the largest disks are not clipped at transect ends.
   end_margin <- max(if(!is.null(config$radii)) config$radii else radii)
   plots <- make_synthetic_plots(transects, split$train_ids,
                                 spacing_m = config$spacing_m, end_margin_m = end_margin)
   disks <- carve_train_transects(plots, transects, radius)
   comb  <- degrade_combined_transects(transects, disks, split$validate_ids, split$test_ids)

   message('   ', nrow(plots), ' synthetic plots; carved to radius ', radius, ' m (clipped to source transects)')


   if(save_gis) {                                                             # dump centers, clipped disks, and training polys for QGIS
      gis_dir <- file.path(radius_dir, 'gis')
      dir.create(gis_dir, recursive = TRUE, showWarnings = FALSE)
      train_polys <- transects[transects$poly %in% split$train_ids, c('subclass', 'poly')]
      sf::st_write(plots,       file.path(gis_dir, 'plot_centers.gpkg'), delete_dsn = TRUE, quiet = TRUE)
      sf::st_write(disks,       file.path(gis_dir, 'plot_disks.gpkg'),   delete_dsn = TRUE, quiet = TRUE)
      sf::st_write(train_polys, file.path(gis_dir, 'train_polys.gpkg'),  delete_dsn = TRUE, quiet = TRUE)
      message('   Saved GIS layers (plot_centers / plot_disks / train_polys) to ', gis_dir)
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
      radius_m           = radius,
      pixel_m            = pixel_m,
      n_plots            = nrow(plots),
      radius_px          = round(radius / pixel_m, 2),
      px_per_plot_geom   = round(pi * (radius / pixel_m)^2),
      train_pixels_actual = sum(patches$train_masks)
   ), file.path(radius_dir, 'degrade_meta.rds'))

   message('degrade prep complete for radius ', radius, ' m')
}
