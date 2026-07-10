# degrade.R
# Pixel-degradation experiment for the marshmap U-Net.
#
# Measures how U-Net accuracy responds to plot SIZE (sampling area) at fixed 8 cm
# resolution, holding plot count and centers constant. Existing polygon-labeled
# TRAINING transects are replaced with synthetic radius-r point plots (disks);
# validation and test labels are left at full extent, so the evaluation target is
# identical across every radius and any accuracy difference is attributable to
# training-pixel density per plot alone.
#
# The pipeline is transect-based: carving a training label to radius r simply means
# restricting the TRAIN loss mask to disk pixels. Because U-Net loss is masked
# (pixels outside a labeled polygon are excluded), poly-interior pixels outside the
# disks are automatically "unknown, not background" -- no ignore/context layering is
# needed (contrast the raster-label design in pixel_degradation_experiment.md, which
# predates wiring against the repo).
#
# Flow (mirrors unet_prep -> train):
#   degrade()          launcher: builds the radius x seed grid, dispatches Slurm jobs
#   do_degrade_prep()  per-radius worker: carve training transects, export patches
#   do_degrade()       per-cell worker: train on carved patches with a given seed,
#                      evaluate on the full-extent test fold, write one tidy result row
#   summarize_degrade() aggregate result rows over seeds; table + plot vs radius
#
# See inst/dev/pixel_degradation_experiment.md for the full design.


# ---------------------------------------------------------------------------
# read_degrade_config()
# Merge model + train + experiment YAMLs (each overriding the previous), lowercase
# the site (to match do_train's file/dir conventions), and fill U-Net defaults.
# ---------------------------------------------------------------------------
read_degrade_config <- function(model, train, exp) {

   config <- read_yaml(file.path(the$parsdir, 'unet', paste0(model, '.yml')))
   if(!is.null(train))
      config <- modifyList(config, read_yaml(file.path(the$parsdir, 'unet', paste0(train, '.yml'))))
   config <- modifyList(config, read_yaml(file.path(the$parsdir, 'unet', paste0(exp, '.yml'))))

   config$site <- tolower(config$site)                                        # match do_train's lowercase site convention
   config <- unet_config_defaults(config)                                     # derive helper fields + fill defaults (resolve_dir normalizes site case)
   config
}


# ---------------------------------------------------------------------------
# degrade_dir()
# Root directory for a degrade experiment: <unetdir>/<model>/degrade/
# ---------------------------------------------------------------------------
degrade_dir <- function(config, model) {
   file.path(resolve_dir(the$unetdir, config$site), model, 'degrade')
}


# ---------------------------------------------------------------------------
# Fold + radius naming. Experiments run over one or more spatial FOLDS (each a
# test/val group pair) x plot RADII, where radius = Inf is the full-transect anchor.
#   degrade_rtag(r)         -> 'r040' ... 'r125', or 'rfull' for the r=Inf anchor
#   degrade_fold_tag(test)  -> 'f1' (or 'f1_6' for a multi-group test set)
#   degrade_fold_dir(...)   -> <degrade_dir>/f<test>/  (patches, fits, pinned weights)
# ---------------------------------------------------------------------------
degrade_rtag <- function(radius)
   if(is.infinite(radius)) 'rfull' else sprintf('r%03d', round(radius * 100))

degrade_fold_tag <- function(test) paste0('f', paste(test, collapse = '_'))

degrade_fold_dir <- function(config, model, test)
   file.path(degrade_dir(config, model), degrade_fold_tag(test))


# ---------------------------------------------------------------------------
# degrade_folds()
# Normalize a folds spec to a data.frame(test, val). Accepts (in priority order) the
# `folds` argument, then config$folds (YAML), then the single test_group/val_group.
# List form may be list(c(test, val), ...) or list(list(test=, val=), ...).
# ---------------------------------------------------------------------------
degrade_folds <- function(config, folds = NULL) {

   if(is.null(folds)) folds <- config$folds
   if(is.null(folds)) {                                                       # fall back to the base config's single fold
      if(is.null(config$test_group) || is.null(config$val_group))
         stop('no folds given: supply `folds`, config$folds, or test_group + val_group')
      return(data.frame(test = config$test_group[1], val = config$val_group[1]))
   }
   if(is.data.frame(folds))
      return(folds[, c('test', 'val')])
   pick <- function(f, key, idx) as.integer(if(is.list(f) && !is.null(f[[key]])) f[[key]] else f[[idx]])
   test <- vapply(folds, pick, integer(1), key = 'test', idx = 1)            # accepts c(test,val) or list(test=,val=)
   val  <- vapply(folds, pick, integer(1), key = 'val',  idx = 2)
   data.frame(test = test, val = val)
}


# ---------------------------------------------------------------------------
# degrade_pinned_weights()
# Class weights (internal 0..n-1 order) from the FULL uncarved training transects of a
# fold, using train_unet.py's 'freq' formula. Pins the loss weighting so it does not
# vary with plot radius (threat 5). do_degrade_prep writes these once per fold; every
# cell in the fold then trains with the same vector.
# ---------------------------------------------------------------------------
degrade_pinned_weights <- function(input_stack, transects, train_ids, config) {

   train <- transects[transects$poly %in% train_ids, ]
   v     <- terra::vect(train)
   tmpl  <- terra::crop(input_stack[[1]], terra::ext(v))                      # input grid over the training extent
   r     <- terra::mask(terra::rasterize(v, tmpl, field = 'subclass'), tmpl)  # drop pixels with no imagery

   vals <- terra::values(r)
   vals <- vals[!is.na(vals)]
   tab  <- table(vals)

   orig     <- as.integer(names(config$class_mapping))                        # original class ids ...
   internal <- as.integer(config$class_mapping)                               # ... and their internal 0..n-1 indices
   counts   <- numeric(length(config$classes))
   for(k in seq_along(orig)) {
      key <- as.character(orig[k])
      counts[internal[k] + 1] <- if(key %in% names(tab)) as.numeric(tab[[key]]) else 0
   }

   w <- 1 / (counts + 1e-6)                                                   # 'freq' weighting, normalized as in train_unet.py
   w <- w / sum(w) * length(config$classes)
   list(original_classes  = orig[order(internal)],
        class_pixel_counts = counts,
        class_weights      = w)
}


# ---------------------------------------------------------------------------
# min_bbox() / rot2d()
# Minimum-area rotated bounding box of a polygon, and a 2-D rotation. Reused from
# inst/scripts/transects_to_circles.R. min_bbox gives each transect a local frame
# (center cx/cy, long-axis angle, extent xmin..ymax in that rotated frame) so
# make_synthetic_plots can walk plot centers straight down the transect centerline.
# ---------------------------------------------------------------------------
min_bbox <- function(poly) {                                                  # min-area rotated bbox via rotating calipers over hull edges

   xy <- sf::st_coordinates(sf::st_convex_hull(poly))[, 1:2]
   n  <- nrow(xy) - 1                                                          # drop the closing vertex
   xy <- xy[seq_len(n), , drop = FALSE]
   cx <- mean(xy[, 1])
   cy <- mean(xy[, 2])
   cc <- sweep(xy, 2, c(cx, cy))                                              # center on centroid

   best <- list(area = Inf)
   for(i in seq_len(n)) {
      j     <- i %% n + 1
      angle <- atan2(cc[j, 2] - cc[i, 2], cc[j, 1] - cc[i, 1])                # align an edge with the x-axis
      rot   <- rot2d(cc, -angle)
      xr <- range(rot[, 1]); yr <- range(rot[, 2])
      w  <- diff(xr);        h  <- diff(yr)
      if(h > w) {                                                             # keep the long axis as x
         angle <- angle + pi / 2
         rot   <- rot2d(cc, -angle)
         xr <- range(rot[, 1]); yr <- range(rot[, 2])
         w  <- diff(xr);        h  <- diff(yr)
      }
      if(w * h < best$area)
         best <- list(area = w * h, angle = angle, cx = cx, cy = cy,
                      xmin = xr[1], xmax = xr[2], ymin = yr[1], ymax = yr[2])
   }
   best
}

rot2d <- function(m, angle) {                                                 # rotate 2-column matrix m by angle (radians)
   ca <- cos(angle)
   sa <- sin(angle)
   cbind(ca * m[, 1] - sa * m[, 2], sa * m[, 1] + ca * m[, 2])
}


# ---------------------------------------------------------------------------
# make_synthetic_plots()
# Place plot centers along the CENTERLINE of each TRAINING transect at fixed
# min-separation spacing. Centers are radius-independent (held fixed across all
# radii and seeds, phase 1), so plot radius is the only thing that varies. Because
# centers sit on the transect long axis and are kept end_margin_m in from each end,
# a disk of up to end_margin_m radius stays inside the digitized transect (modulo
# lateral clipping in carve_train_transects) -- no labels are fabricated outside the
# ground truth. This replaces the old grid-buffer design, whose full disks spilled
# out of narrow transects and fabricated labels that grew with radius (confound).
#
#   transects      : full prepared sf (post spatial_holdout), with 'subclass' and
#                    'poly'. CRS must be projected (metres).
#   train_ids      : vector of `poly` values that are TRAINING (from the fixed split).
#   spacing_m      : center-to-center spacing along the transect centerline.
#   end_margin_m   : drop the portion of centerline within this distance of a transect
#                    end. Set to the experiment's MAX radius so the biggest disks are
#                    not clipped at the ends; transects shorter than 2*end_margin_m
#                    get no centers.
#   plot_id_offset : synthetic plot ids start here, above any real `poly` value, so
#                    they never collide with original val/test ids.
#
#   returns        : sf POINT with fields subclass, src_poly, poly (unique plot id).
# ---------------------------------------------------------------------------
make_synthetic_plots <- function(transects, train_ids, spacing_m = 2.5, end_margin_m = 1.25,
                                 plot_id_offset = 100000L) {

   if(isTRUE(sf::st_is_longlat(transects)))
      stop('transects must be in a projected CRS (metres) for metre-based plot spacing/radii')
   if(max(transects$poly, na.rm = TRUE) >= plot_id_offset)
      stop('real poly ids reach ', max(transects$poly, na.rm = TRUE),
           '; raise plot_id_offset above that to avoid id collisions')

   train <- transects[transects$poly %in% train_ids, c('subclass', 'poly')]

   out <- vector('list', nrow(train))
   for(k in seq_len(nrow(train))) {                                           # one training transect at a time
      poly <- train[k, ]
      bb   <- min_bbox(poly)                                                  # local frame: long axis + angle
      if(bb$xmax - bb$xmin < 2 * end_margin_m)                                # too short to hold a margin-trimmed center
         next
      xs <- seq(bb$xmin + end_margin_m, bb$xmax - end_margin_m, by = spacing_m)
      p  <- rot2d(cbind(xs, (bb$ymin + bb$ymax) / 2), bb$angle)               # centerline points, rotated back to map frame
      p[, 1] <- p[, 1] + bb$cx
      p[, 2] <- p[, 2] + bb$cy
      pts <- sf::st_as_sf(data.frame(x = p[, 1], y = p[, 2]),
                          coords = c('x', 'y'), crs = sf::st_crs(train))
      inside <- sf::st_within(pts, poly, sparse = FALSE)[, 1]                 # keep centers actually inside this transect
      pts <- pts[inside, , drop = FALSE]
      if(nrow(pts) == 0)
         next
      pts$subclass <- poly$subclass
      pts$src_poly <- poly$poly
      out[[k]] <- pts
   }

   centers <- do.call(rbind, Filter(Negate(is.null), out))
   if(is.null(centers) || nrow(centers) == 0)
      stop('no synthetic plot centers placed; check spacing_m / end_margin_m vs transect sizes')
   centers$poly <- plot_id_offset + seq_len(nrow(centers))                    # unique synthetic plot ids
   centers[, c('subclass', 'src_poly', 'poly')]
}


# ---------------------------------------------------------------------------
# carve_train_transects()
# Turn plot centers into radius-r disks carrying the plot's subclass, each CLIPPED
# to its source transect. These disks replace the training transects; the train loss
# mask then covers disk pixels only. Clipping to the source poly guarantees no disk
# labels ground outside the digitized transect, so the label SET is never fabricated
# as radius grows -- radius controls sampled AREA only. (The old, unclipped version
# spilled full disks past narrow transects and confounded size with label fabrication.)
#
#   plots     : sf POINT from make_synthetic_plots (fields subclass, src_poly, poly).
#   transects : full prepared sf; 'poly' is matched against plots$src_poly for clipping.
#   radius_m  : disk radius in metres (map units; CRS must be projected).
#
#   returns   : sf POLYGON with fields subclass, poly (disks empty after clip dropped).
# ---------------------------------------------------------------------------
carve_train_transects <- function(plots, transects, radius_m) {

   disks    <- sf::st_buffer(plots, dist = radius_m)                          # true metre disks on a projected CRS
   src_geom <- sf::st_geometry(transects)[match(plots$src_poly, transects$poly)]
   dg       <- sf::st_geometry(disks)
   clipped  <- sf::st_sfc(lapply(seq_along(dg),                               # clip each disk to its own source transect
                                 function(i) sf::st_intersection(dg[[i]], src_geom[[i]])),
                          crs = sf::st_crs(disks))
   sf::st_geometry(disks) <- clipped
   disks <- disks[!sf::st_is_empty(disks), ]                                  # drop any disk fully outside its poly
   disks[, c('subclass', 'poly')]
}


# ---------------------------------------------------------------------------
# degrade_combined_transects()
# Build the single sf + id vectors that unet_extract_training_patches expects:
# carved disks as TRAINING, original val/test transects at FULL extent. Disk ids
# (from make_synthetic_plots) live above real poly ids, so `poly %in% ids`
# partitions cleanly.
#
#   returns : list(transects, train_ids, validate_ids, test_ids)
# ---------------------------------------------------------------------------
degrade_combined_transects <- function(transects, disks, validate_ids, test_ids) {

   train_sf   <- disks[, c('subclass', 'poly')]
   holdout_sf <- transects[transects$poly %in% c(validate_ids, test_ids), c('subclass', 'poly')]
   combined   <- rbind(train_sf, holdout_sf)

   list(transects    = combined,
        train_ids     = train_sf$poly,
        validate_ids  = validate_ids,
        test_ids      = test_ids)
}


# ---------------------------------------------------------------------------
# degrade()  -- LAUNCHER
# Dispatch the pixel-degradation experiment. Two stages, because prep is per-radius
# but training is per (radius x seed):
#   stage 'prep'  : one CPU job per radius -> carve + export patches
#   stage 'train' : one GPU job per (radius x seed) cell -> train + evaluate + row
# Run 'prep' first; once those jobs finish, run 'train'.
#
#   model / train : base model + training YAMLs in <pars>/unet/ (as for train())
#   exp           : experiment YAML in <pars>/unet/ with radii, seeds, spacing_m,
#                   test_group, val_group
#   stage         : 'prep' or 'train'
#   radii / seeds : override the experiment YAML if supplied
# ---------------------------------------------------------------------------
#' Run the U-Net pixel-degradation experiment
#'
#' Launches the pixel-degradation experiment, which measures how U-Net accuracy
#' responds to field plot size (sampling footprint) at fixed resolution. Training
#' transects are carved to radius-`r` disks around fixed synthetic plot centers,
#' while validation and test labels stay at full extent. Runs in two stages: `prep`
#' carves and exports patches (one CPU job per radius); `train` fits and evaluates
#' one GPU job per radius x seed cell. Run `prep` first, then `train` once prep
#' completes. See `inst/dev/pixel_degradation_experiment.md`.
#'
#' @param model Base name of the model `.yml` in `<pars>/unet/` (e.g. `'primary_v6'`).
#' @param train Base name of the training `.yml` in `<pars>/unet/`, or NULL.
#' @param exp Base name of the experiment `.yml` in `<pars>/unet/` supplying
#'   `radii`, `seeds`, `spacing_m`, `test_group`, `val_group`.
#' @param stage `'prep'` (carve + export patches, one job per radius) or `'train'`
#'   (train + evaluate, one job per radius x seed cell).
#' @param radii Optional numeric vector of plot radii (m); overrides the experiment YAML.
#' @param seeds Optional integer vector of training seeds; overrides the experiment YAML.
#' @param resources Slurm launch resources; see \link[slurmcollie]{launch}. Take
#'   priority over the stage defaults. `train` requires a GPU.
#' @param local If TRUE, run locally; otherwise spawn batch jobs on Unity.
#' @param trap If TRUE, trap errors in local mode (see [train()]).
#' @param requirecuda If TRUE (default), abort if CUDA is unavailable (train stage).
#' @param save_gis If TRUE (prep stage only), write plot centers, clipped disks, and
#'   training polys as GeoPackages under `f<test>/r<NNN>/gis/` for inspection in QGIS.
#' @param folds Optional fold spec overriding `config$folds`: a list of `c(test, val)`
#'   group pairs (or a data.frame with `test`/`val` columns). Defaults to the base
#'   config's single `test_group`/`val_group`.
#' @param anchor If TRUE, also run the full-transect (r = Inf) anchor as an endpoint
#'   ("r = infinity"). Defaults to `config$anchor`.
#' @param pin_weights If TRUE, train every cell with class weights pinned to the fold's
#'   full-transect frequency, removing radius-dependent loss weighting. Defaults to
#'   `config$pin_class_weights`.
#' @param comment Optional slurmcollie comment.
#' @importFrom slurmcollie launch get_resources
#' @importFrom yaml read_yaml
#' @export


degrade <- function(model = 'primary_v6', train = 'train', exp = 'degrade',
                    stage = c('prep', 'train'), radii = NULL, seeds = NULL,
                    resources = NULL, local = FALSE, trap = TRUE,
                    requirecuda = TRUE, save_gis = FALSE, folds = NULL,
                    anchor = NULL, pin_weights = NULL, comment = NULL) {


   stage  <- match.arg(stage)
   config <- read_degrade_config(model, train, exp)

   if(is.null(radii)) radii <- config$radii
   if(is.null(seeds)) seeds <- config$seeds
   if(is.null(radii) || is.null(seeds))
      stop('radii and seeds must be given in the experiment YAML (', exp, '.yml) or as arguments')

   folds <- degrade_folds(config, folds)                                      # data.frame(test, val), one row per fold
   if(is.null(anchor))      anchor      <- isTRUE(config$anchor)              # add the full-transect (r = Inf) endpoint?
   if(is.null(pin_weights)) pin_weights <- isTRUE(config$pin_class_weights)   # pin loss weights to full-transect freq?
   radii_all <- if(anchor) c(radii, Inf) else radii

   message(nrow(folds), ' fold(s) [test/val ',
           paste(sprintf('%s/%s', folds$test, folds$val), collapse = ', '), ']; ',
           length(radii_all), ' radii', if(anchor) ' (incl. full-transect anchor)' else '',
           '; pin_weights = ', pin_weights)


   if(stage == 'prep') {

      resources <- get_resources(resources, list(ncpus = 1, memory = 180, walltime = '10:00:00'))
      if(is.null(comment))
         comment <- paste0('degrade prep ', model, ' / ', exp)

      pgrid <- expand.grid(radius = radii_all, fold = seq_len(nrow(folds)),   # one CPU job per fold x radius
                           KEEP.OUT.ATTRS = FALSE)
      pgrid <- cbind(pgrid, test = folds$test[pgrid$fold], val = folds$val[pgrid$fold])

      launch('do_degrade_prep', reps = seq_len(nrow(pgrid)), repname = 'rep',
             moreargs = list(pgrid = pgrid, exp = exp, model = model, train = train, save_gis = save_gis),
             local = local, trap = trap, resources = resources, comment = comment)

   } else {

      resources <- get_resources(resources, list(
         ncpus = 1, ngpus = 1, constraint = 'l40s',
         partition.gpu = 'gpu-preempt,gpu', memory = 64, walltime = '04:00:00'))
      if(is.null(comment))
         comment <- paste0('degrade train ', model, ' / ', exp)

      grid <- expand.grid(radius = radii_all, seed = seeds, fold = seq_len(nrow(folds)),  # one GPU job per fold x radius x seed
                          KEEP.OUT.ATTRS = FALSE)
      grid <- cbind(grid, test = folds$test[grid$fold], val = folds$val[grid$fold])

      launch('do_degrade', reps = seq_len(nrow(grid)), repname = 'rep',
             moreargs = list(grid = grid, exp = exp, model = model, train = train,
                             requirecuda = requirecuda, pin_weights = pin_weights),
             local = local, trap = trap, resources = resources, comment = comment)
   }
}


# ---------------------------------------------------------------------------
# summarize_degrade()
# Aggregate per-cell result rows over seeds; compact table + base-R plot of accuracy
# and per-class recall vs plot radius.
#
#   exp / model : locate the experiment directory (ignored if `results` supplied)
#   results     : optional data.frame of rows (else read cell_r*_s*.csv files)
# ---------------------------------------------------------------------------
#' Summarize a pixel-degradation experiment
#'
#' Reads the per-cell result rows written by [do_degrade()], averages over folds and
#' seeds, prints a compact table, and plots overall CCR (and per-class recall) versus
#' plot radius. The full-transect anchor (radius = Inf) is drawn as a horizontal
#' reference line rather than a point.
#'
#' @param exp Experiment YAML base name (to locate the results directory).
#' @param model Model YAML base name (to locate the results directory).
#' @param results Optional data.frame of result rows; if NULL, reads the fold-tagged
#'   `cell_f*.csv` files (falling back to the legacy pilot `cell_r*.csv`).
#' @param train Training YAML base name (used only to resolve the site/config).
#' @param error Error-bar type drawn on each series: `'se'` (standard error of the mean
#'   over folds x seeds, default), `'sd'` (standard deviation), or `'none'`.
#' @param pilot If TRUE, summarize the legacy single-fold pilot (`cell_r*.csv`) instead
#'   of the fold-tagged runs.
#' @returns Invisibly, the aggregated data.frame (per-radius means, `_sd`, `_se`, `n`).
#' @export


summarize_degrade <- function(exp = 'degrade', model = 'primary_v6', results = NULL, train = 'train',
                              error = c('se', 'sd', 'none'), pilot = FALSE) {

   error <- match.arg(error)


   if(is.null(results)) {
      config <- read_degrade_config(model, train, exp)
      dir    <- degrade_dir(config, model)
      files  <- list.files(dir, pattern = if(pilot) '^cell_r.*\\.csv$' else '^cell_f.*\\.csv$', full.names = TRUE)
      if(length(files) == 0 && !pilot) {                                     # no fold-tagged runs yet -> show the legacy pilot
         files <- list.files(dir, pattern = '^cell_r.*\\.csv$', full.names = TRUE)
         if(length(files)) message('No fold-tagged results found; showing the legacy pilot (cell_r*.csv).')
      }
      if(length(files) == 0)
         stop('no result files found in ', dir)
      results <- do.call(rbind, lapply(files, read.csv, stringsAsFactors = FALSE))
   }

   recall_cols <- grep('^recall_', names(results), value = TRUE)              # ccr, kappa, and each per-class recall
   metric_cols <- c('ccr', 'kappa', recall_cols)

   by_r <- list(radius_m = results$radius_m)                                 # aggregate over folds x seeds, by radius
   agg  <- aggregate(results[, metric_cols, drop = FALSE], by = by_r, FUN = mean)
   sds  <- aggregate(results[, metric_cols, drop = FALSE], by = by_r, FUN = sd)
   names(sds)[-1] <- paste0(metric_cols, '_sd')
   ns   <- aggregate(list(n       = results$ccr),        by = by_r, FUN = length)
   nf   <- aggregate(list(n_folds = results$test_group), by = by_r, FUN = function(x) length(unique(x)))
   pp   <- aggregate(list(px_per_plot = results$px_per_plot), by = by_r, FUN = function(x) mean(x))  # NA for anchor
   agg  <- Reduce(function(a, b) merge(a, b, by = 'radius_m'), list(agg, sds, ns, nf, pp))
   agg  <- agg[order(agg$radius_m), ]
   for(m in metric_cols)                                                      # standard error of each mean
      agg[[paste0(m, '_se')]] <- agg[[paste0(m, '_sd')]] / sqrt(agg$n)

   cat('\nMean accuracy vs plot radius (averaged over folds x seeds):\n\n')
   print(agg[, c('radius_m', 'px_per_plot', 'n_folds', 'n', metric_cols)], row.names = FALSE, digits = 3)

   anc <- agg[is.infinite(agg$radius_m), , drop = FALSE]                      # full-transect anchor -> reference line
   agg <- agg[is.finite(agg$radius_m),  , drop = FALSE]                       # finite radii -> the curve

   # --- series (metric, colour, symbol) drawn in this order; recall colours keyed by class ---
   rec_pal   <- c('101' = 'darkblue', '102' = 'darkgreen', '103' = 'orange', '104' = 'lightgreen')
   rec_class <- sub('^recall_', '', recall_cols)
   rec_col   <- unname(rec_pal[rec_class])                                    # NA for any class not in the palette
   if(anyNA(rec_col)) rec_col[is.na(rec_col)] <- grDevices::rainbow(sum(is.na(rec_col)))
   names(rec_col) <- recall_cols

   series_m   <- c('ccr', 'kappa', recall_cols)                              # draw / legend order
   series_col <- c('black', 'grey40', rec_col)
   series_pch <- c(19, 1, rep(2, length(recall_cols)))
   series_lty <- c(1, 2, rep(3, length(recall_cols)))
   names(series_col) <- names(series_pch) <- names(series_lty) <- series_m

   K       <- length(series_m)                                              # jitter x per series so error bars don't overlap
   gaps    <- diff(sort(unique(agg$radius_m)))
   min_gap <- if(length(gaps)) min(gaps) else 1
   dx      <- min_gap * 0.06
   offs    <- (seq_len(K) - (K + 1) / 2) * dx
   names(offs) <- series_m

   ebar <- function(m) {                                                     # +/-1 SE (or SD) bar at the series' jittered x
      e <- switch(error, se = agg[[paste0(m, '_se')]], sd = agg[[paste0(m, '_sd')]], none = NULL)
      if(!is.null(e))
         suppressWarnings(arrows(agg$radius_m + offs[m], agg[[m]] - e,
                                 agg$radius_m + offs[m], agg[[m]] + e,
                                 angle = 90, code = 3, length = 0.03, col = series_col[m]))
   }

   plot(agg$radius_m + offs['ccr'], agg$ccr, type = 'b', pch = 19, ylim = c(0, 1),
        xlim = range(agg$radius_m) + c(-1, 1) * (dx * K / 2 + min_gap * 0.05),
        xlab = 'plot radius (m)', ylab = 'accuracy / recall',
        main = 'U-Net accuracy vs plot size', col = 'black')
   ebar('ccr')
   lines(agg$radius_m + offs['kappa'], agg$kappa, type = 'b', pch = 1, lty = 2, col = 'grey40')
   for(m in recall_cols) {                                                    # each per-class recall + its own error bars
      lines(agg$radius_m + offs[m], agg[[m]], type = 'b', pch = 2, lty = 3, col = series_col[m])
      ebar(m)
   }

   if(nrow(anc)) {                                                            # full-transect anchor: CCR reference line
      abline(h = anc$ccr[1], lty = 4, lwd = 1.5, col = 'red')
      text(par('usr')[1], anc$ccr[1], sprintf(' full-transect CCR = %.3f', anc$ccr[1]),
           adj = c(0, -0.4), cex = 0.8, col = 'red')
   }

   ccr_lab  <- if(error == 'none') 'CCR' else sprintf('CCR (+/-1 %s)', toupper(error))
   leg_txt  <- c(ccr_lab, 'Kappa', recall_cols)
   leg_pch  <- series_pch; leg_lty <- series_lty; leg_col <- series_col
   if(nrow(anc)) { leg_txt <- c(leg_txt, 'full transect (CCR)')              # add anchor to the legend
                   leg_pch <- c(leg_pch, NA); leg_lty <- c(leg_lty, 4); leg_col <- c(leg_col, 'red') }
   legend('bottomright', leg_txt, pch = leg_pch, lty = leg_lty, col = leg_col, bty = 'n')

   out <- rbind(agg, anc)                                                     # finite radii + anchor, for the caller
   invisible(out[order(out$radius_m), ])
}
