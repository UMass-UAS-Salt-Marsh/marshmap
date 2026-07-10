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
#'   training polys as GeoPackages under `r<NNN>/gis/` for inspection in QGIS.
#' @param comment Optional slurmcollie comment.
#' @importFrom slurmcollie launch get_resources
#' @importFrom yaml read_yaml
#' @export


degrade <- function(model = 'primary_v6', train = 'train', exp = 'degrade',
                    stage = c('prep', 'train'), radii = NULL, seeds = NULL,
                    resources = NULL, local = FALSE, trap = TRUE,
                    requirecuda = TRUE, save_gis = FALSE, comment = NULL) {


   stage  <- match.arg(stage)
   config <- read_degrade_config(model, train, exp)

   if(is.null(radii)) radii <- config$radii
   if(is.null(seeds)) seeds <- config$seeds
   if(is.null(radii) || is.null(seeds))
      stop('radii and seeds must be given in the experiment YAML (', exp, '.yml) or as arguments')


   if(stage == 'prep') {

      resources <- get_resources(resources, list(ncpus = 1, memory = 180, walltime = '10:00:00'))
      if(is.null(comment))
         comment <- paste0('degrade prep ', model, ' / ', exp)

      launch('do_degrade_prep', reps = seq_along(radii), repname = 'rep',
             moreargs = list(radii = radii, exp = exp, model = model, train = train, save_gis = save_gis),
             local = local, trap = trap, resources = resources, comment = comment)

   } else {

      resources <- get_resources(resources, list(
         ncpus = 1, ngpus = 1, constraint = 'l40s',
         partition.gpu = 'gpu-preempt,gpu', memory = 64, walltime = '04:00:00'))
      if(is.null(comment))
         comment <- paste0('degrade train ', model, ' / ', exp)

      grid <- expand.grid(radius = radii, seed = seeds, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)

      launch('do_degrade', reps = seq_len(nrow(grid)), repname = 'rep',
             moreargs = list(grid = grid, exp = exp, model = model, train = train, requirecuda = requirecuda),
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
#' Reads the per-cell result rows written by [do_degrade()], averages over seeds,
#' prints a compact table, and plots overall CCR (and per-class recall) versus plot
#' radius.
#'
#' @param exp Experiment YAML base name (to locate the results directory).
#' @param model Model YAML base name (to locate the results directory).
#' @param results Optional data.frame of result rows; if NULL, reads `cell_*.csv`
#'   files from the experiment directory.
#' @param train Training YAML base name (used only to resolve the site/config).
#' @param error Error-bar type drawn on the CCR curve: `'se'` (standard error of the
#'   mean over seeds, default), `'sd'` (between-seed standard deviation), or `'none'`.
#' @returns Invisibly, the aggregated data.frame (with `ccr_sd`, `ccr_se`, `n_seeds`).
#' @export


summarize_degrade <- function(exp = 'degrade', model = 'primary_v6', results = NULL, train = 'train',
                              error = c('se', 'sd', 'none')) {

   error <- match.arg(error)


   if(is.null(results)) {
      config <- read_degrade_config(model, train, exp)
      files  <- list.files(degrade_dir(config, model), pattern = '^cell_r.*\\.csv$', full.names = TRUE)
      if(length(files) == 0)
         stop('no result files found in ', degrade_dir(config, model))
      results <- do.call(rbind, lapply(files, read.csv, stringsAsFactors = FALSE))
   }

   recall_cols <- grep('^recall_', names(results), value = TRUE)              # aggregate ccr, kappa, and each per-class recall over seeds
   metric_cols <- c('ccr', 'kappa', recall_cols)

   agg <- aggregate(results[, metric_cols, drop = FALSE],
                    by = list(radius_m = results$radius_m, px_per_plot = results$px_per_plot),
                    FUN = mean)
   agg <- agg[order(agg$radius_m), ]

   spread <- aggregate(list(ccr_sd = results$ccr, n_seeds = results$ccr),     # between-seed spread of CCR, per radius
                       by = list(radius_m = results$radius_m),
                       FUN = function(x) c(sd = sd(x), n = length(x)))
   spread <- data.frame(radius_m = spread$radius_m,
                        ccr_sd  = spread$ccr_sd[, 'sd'],
                        n_seeds = spread$ccr_sd[, 'n'])
   agg <- merge(agg, spread, by = 'radius_m')
   agg <- agg[order(agg$radius_m), ]
   agg$ccr_se <- agg$ccr_sd / sqrt(agg$n_seeds)                               # standard error of the mean CCR

   cat('\nMean accuracy vs plot radius (averaged over seeds):\n\n')
   print(agg, row.names = FALSE, digits = 3)

   err <- switch(error, se = agg$ccr_se, sd = agg$ccr_sd, none = NULL)        # half-height of the CCR error bar

   with(agg, plot(radius_m, ccr, type = 'b', pch = 19, ylim = c(0, 1),
                  xlab = 'plot radius (m)', ylab = 'accuracy / recall',
                  main = 'U-Net accuracy vs plot size'))
   if(!is.null(err))                                                          # CCR error bars (+/- 1 SE or SD across seeds)
      suppressWarnings(arrows(agg$radius_m, agg$ccr - err, agg$radius_m, agg$ccr + err,
                              angle = 90, code = 3, length = 0.03, col = 'black'))
   with(agg, lines(radius_m, kappa, type = 'b', pch = 1, lty = 2))
   if(length(recall_cols)) {
      cols <- seq_along(recall_cols) + 1
      for(k in seq_along(recall_cols))
         with(agg, lines(radius_m, agg[[recall_cols[k]]], type = 'b', pch = 2, lty = 3, col = cols[k]))
   }
   ccr_lab <- if(error == 'none') 'CCR'                                       # note the error-bar convention on the CCR entry
              else sprintf('CCR (+/-1 %s)', toupper(error))
   legend('bottomright',
          c(ccr_lab, 'Kappa', recall_cols),
          pch = c(19, 1, rep(2, length(recall_cols))),
          lty = c(1, 2, rep(3, length(recall_cols))),
          col = c('black', 'black', seq_along(recall_cols) + 1), bty = 'n')

   invisible(agg)
}
