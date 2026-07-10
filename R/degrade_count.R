# degrade_count.R
# Site-COUNT degradation experiment for the marshmap U-Net.
#
# Companion to the plot-SIZE sweep in degrade.R. That experiment held plot count
# constant and shrank each plot; this one holds plot SIZE constant (a fixed radius)
# and shrinks the NUMBER of training sites (transects) -- the true independent
# sampling unit (plots within a transect are spatially correlated, so extra plots in
# a transect are largely redundant; extra transects are not). It answers "how many
# field sites does the map actually need?" rather than "how big must each plot be?".
#
# For each spatial fold we take a random subset of the fold's TRAINING transects,
# place synthetic plots on their centerlines, carve those to fixed-radius disks, and
# train/evaluate exactly as in degrade(). Validation and test stay at full extent, so
# the evaluation target is identical across every site count. The subset is RESAMPLED
# per seed (a fresh permutation seeded by `seed`, nested so lower counts are subsets
# of higher counts within a seed), which turns seed-to-seed spread into an honest
# estimate of how much the answer depends on WHICH sites you happened to sample.
#
# Unlike degrade() this is SINGLE-STAGE: because the site subset depends on the seed,
# carving is seed-specific, so each fold x count x seed cell does the whole chain
# (subsample -> carve -> extract -> export -> train -> evaluate -> row) in one job.
#
# Flow:
#   degrade_count()          launcher: builds the fold x count x seed grid, dispatches
#   do_degrade_count()       per-cell worker: subsample sites, carve, train, evaluate
#   summarize_degrade_count() aggregate rows over folds x seeds; table + plot vs n_sites
#
# Reuses the size-experiment machinery in degrade.R: read_degrade_config, degrade_dir,
# degrade_fold_dir/_tag, degrade_folds, degrade_pinned_weights, make_synthetic_plots,
# carve_train_transects, degrade_combined_transects.


# ---------------------------------------------------------------------------
# degrade_ctag()
# Directory / file tag for one site count: 'c004' ... 'c064', or 'call' for the
# all-sites anchor (count = Inf). Mirrors degrade_rtag().
# ---------------------------------------------------------------------------
degrade_ctag <- function(count)
   if(is.infinite(count)) 'call' else sprintf('c%03d', count)


# ---------------------------------------------------------------------------
# degrade_count()  -- LAUNCHER
# Dispatch the site-count degradation experiment. One GPU job per fold x count x seed
# cell; each cell is self-contained (subsample + carve + train + evaluate), so there
# is no separate prep stage. Run it once and summarize when the array finishes.
#
#   model / train : base model + training YAMLs in <pars>/unet/ (as for train())
#   exp           : experiment YAML in <pars>/unet/ (supplies folds, seeds, and
#                   optionally counts / count_radius / count_anchor / pin_class_weights)
#   counts        : integer site counts to sweep; overrides config$counts
#   seeds         : training/subsample seeds; overrides config$seeds
#   radius        : fixed plot radius (m) for every cell; overrides config$count_radius
# ---------------------------------------------------------------------------
#' Run the U-Net site-count degradation experiment
#'
#' Launches the site-count degradation experiment, which measures how U-Net accuracy
#' responds to the NUMBER of training sites (transects) at a fixed plot size. For each
#' spatial fold and site count, a random subset of the fold's training transects is
#' drawn (resampled per seed), synthetic plots are placed on their centerlines and
#' carved to a fixed-radius disk, and the model is trained and evaluated on the fold's
#' full-extent test set. Single-stage: one GPU job per fold x count x seed cell.
#' Companion to [degrade()] (the plot-size sweep); see `degrade_count.R`.
#'
#' @param model Base name of the model `.yml` in `<pars>/unet/` (e.g. `'primary_v6'`).
#' @param train Base name of the training `.yml` in `<pars>/unet/`, or NULL.
#' @param exp Base name of the experiment `.yml` in `<pars>/unet/` supplying `folds`
#'   (or `test_group`/`val_group`) and `seeds`, and optionally `counts`,
#'   `count_radius`, `count_anchor`, `pin_class_weights`.
#' @param counts Optional integer vector of training-site counts to sweep; overrides
#'   `config$counts` (default `c(4, 8, 16, 32, 64)`).
#' @param seeds Optional integer vector of seeds (vary network init, data order, AND
#'   which sites are drawn); overrides the experiment YAML.
#' @param radius Fixed plot radius (m) applied to every cell; overrides
#'   `config$count_radius` (default `0.5`).
#' @param resources Slurm launch resources; see \link[slurmcollie]{launch}. Take
#'   priority over the GPU defaults.
#' @param local If TRUE, run locally; otherwise spawn batch jobs on Unity.
#' @param trap If TRUE, trap errors in local mode (see [train()]).
#' @param requirecuda If TRUE (default), abort if CUDA is unavailable.
#' @param save_gis If TRUE, write plot centers, carved disks, and sampled training
#'   polys as GeoPackages under each cell's `gis/` for inspection in QGIS.
#' @param folds Optional fold spec overriding `config$folds`: a list of `c(test, val)`
#'   group pairs (or a data.frame with `test`/`val` columns).
#' @param anchor If TRUE, also run the all-sites endpoint (`count = Inf`) as the
#'   right-hand anchor of the curve. Defaults to `config$count_anchor`, else TRUE.
#' @param pin_weights If TRUE (default via `config$pin_class_weights`), train every
#'   cell with class weights pinned to the fold's full-transect frequency, so the loss
#'   objective does not shift as sites are dropped.
#' @param comment Optional slurmcollie comment.
#' @importFrom slurmcollie launch get_resources
#' @importFrom yaml read_yaml
#' @export


degrade_count <- function(model = 'primary_v6', train = 'train', exp = 'degrade',
                          counts = NULL, seeds = NULL, radius = NULL,
                          resources = NULL, local = FALSE, trap = TRUE,
                          requirecuda = TRUE, save_gis = FALSE, folds = NULL,
                          anchor = NULL, pin_weights = NULL, comment = NULL) {


   config <- read_degrade_config(model, train, exp)

   if(is.null(counts)) counts <- config$counts
   if(is.null(counts)) counts <- c(4, 8, 16, 32, 64)                          # default site-count sweep
   if(is.null(seeds))  seeds  <- config$seeds
   if(is.null(seeds))
      stop('seeds must be given in the experiment YAML (', exp, '.yml) or as an argument')
   if(is.null(radius))
      radius <- if(!is.null(config$count_radius)) config$count_radius else 0.5 # fixed plot size for the whole sweep

   folds <- degrade_folds(config, folds)                                      # data.frame(test, val), one row per fold
   if(is.null(anchor))
      anchor <- if(!is.null(config$count_anchor)) isTRUE(config$count_anchor) else TRUE
   if(is.null(pin_weights)) pin_weights <- isTRUE(config$pin_class_weights)
   counts <- sort(unique(as.integer(counts)))
   counts_all <- if(anchor) c(counts, Inf) else counts

   message(nrow(folds), ' fold(s) [test/val ',
           paste(sprintf('%s/%s', folds$test, folds$val), collapse = ', '), ']; site counts ',
           paste(counts, collapse = ', '), if(anchor) ' (+ all-sites anchor)' else '',
           '; radius ', radius, ' m; ', length(seeds), ' seeds; pin_weights = ', pin_weights)

   resources <- get_resources(resources, list(
      ncpus = 1, ngpus = 1, constraint = 'l40s',
      partition.gpu = 'gpu-preempt,gpu', memory = 64, walltime = '04:00:00'))
   if(is.null(comment))
      comment <- paste0('degrade count ', model, ' / ', exp)

   grid <- expand.grid(count = counts_all, seed = seeds, fold = seq_len(nrow(folds)),  # one GPU job per fold x count x seed
                       KEEP.OUT.ATTRS = FALSE)
   grid <- cbind(grid, test = folds$test[grid$fold], val = folds$val[grid$fold])

   launch('do_degrade_count', reps = seq_len(nrow(grid)), repname = 'rep',
          moreargs = list(grid = grid, exp = exp, model = model, train = train, radius = radius,
                          requirecuda = requirecuda, pin_weights = pin_weights, save_gis = save_gis),
          local = local, trap = trap, resources = resources, comment = comment)
}


# ---------------------------------------------------------------------------
# summarize_degrade_count()
# Aggregate per-cell rows over folds x seeds by requested site count; compact table +
# base-R plot of accuracy and per-class recall vs the ACTUAL mean number of training
# sites, on a log x-axis. The all-sites anchor (count = Inf) lands naturally as the
# right-most point (at its mean n_sites) and is marked with a vertical guide.
#
#   exp / model : locate the experiment directory (ignored if `results` supplied)
#   results     : optional data.frame of rows (else read countcell_*.csv files)
# ---------------------------------------------------------------------------
#' Summarize a site-count degradation experiment
#'
#' Reads the per-cell rows written by [do_degrade_count()], averages over folds and
#' seeds by requested site count, prints a compact table, and plots overall CCR (and
#' per-class recall) versus the mean number of training sites on a log x-axis. The
#' all-sites anchor (`count = Inf`) is drawn as the right-most point and marked with a
#' vertical guide.
#'
#' @param exp Experiment YAML base name (to locate the results directory).
#' @param model Model YAML base name (to locate the results directory).
#' @param results Optional data.frame of result rows; if NULL, reads `countcell_*.csv`.
#' @param train Training YAML base name (used only to resolve the site/config).
#' @param error Error-bar type drawn on each series: `'se'` (standard error over
#'   folds x seeds, default), `'sd'`, or `'none'`.
#' @returns Invisibly, the aggregated data.frame (per-count means, `_sd`, `_se`, `n`).
#' @export


summarize_degrade_count <- function(exp = 'degrade', model = 'primary_v6', results = NULL,
                                    train = 'train', error = c('se', 'sd', 'none')) {

   error <- match.arg(error)


   if(is.null(results)) {
      config <- read_degrade_config(model, train, exp)
      dir    <- degrade_dir(config, model)
      files  <- list.files(dir, pattern = '^countcell_.*\\.csv$', full.names = TRUE)
      if(length(files) == 0)
         stop('no count result files (countcell_*.csv) found in ', dir)
      results <- do.call(rbind, lapply(files, read.csv, stringsAsFactors = FALSE))
   }

   recall_cols <- grep('^recall_', names(results), value = TRUE)              # ccr, kappa, and each per-class recall
   metric_cols <- c('ccr', 'kappa', recall_cols)

   by_c <- list(count_req = results$count_req)                               # aggregate over folds x seeds, by requested count
   agg  <- aggregate(results[, metric_cols, drop = FALSE], by = by_c, FUN = mean)
   sds  <- aggregate(results[, metric_cols, drop = FALSE], by = by_c, FUN = sd)
   names(sds)[-1] <- paste0(metric_cols, '_sd')
   ns   <- aggregate(list(n            = results$ccr),             by = by_c, FUN = length)
   nf   <- aggregate(list(n_folds      = results$test_group),      by = by_c, FUN = function(x) length(unique(x)))
   nsit <- aggregate(list(n_sites      = results$n_sites),         by = by_c, FUN = mean)   # actual mean sites (x-axis)
   npl  <- aggregate(list(n_plots      = results$n_plots),         by = by_c, FUN = mean)
   ntp  <- aggregate(list(n_train_patches = results$n_train_patches), by = by_c, FUN = mean)
   agg  <- Reduce(function(a, b) merge(a, b, by = 'count_req'), list(agg, sds, ns, nf, nsit, npl, ntp))
   agg  <- agg[order(agg$n_sites), ]
   for(m in metric_cols)                                                      # standard error of each mean
      agg[[paste0(m, '_se')]] <- agg[[paste0(m, '_sd')]] / sqrt(agg$n)

   cat('\nMean accuracy vs number of training sites (averaged over folds x seeds):\n\n')
   show <- agg
   show$count <- ifelse(is.infinite(show$count_req), 'all',
                        as.character(as.integer(ifelse(is.infinite(show$count_req), 0L, show$count_req))))
   print(show[, c('count', 'n_sites', 'n_plots', 'n_train_patches', 'n_folds', 'n', metric_cols)],
         row.names = FALSE, digits = 3)

   # --- series (metric, colour, symbol); recall colours keyed by class (as summarize_degrade) ---
   rec_pal   <- c('101' = 'darkblue', '102' = 'darkgreen', '103' = 'orange', '104' = 'lightgreen')
   rec_class <- sub('^recall_', '', recall_cols)
   rec_col   <- unname(rec_pal[rec_class])
   if(anyNA(rec_col)) rec_col[is.na(rec_col)] <- grDevices::rainbow(sum(is.na(rec_col)))
   names(rec_col) <- recall_cols

   series_m   <- c('ccr', 'kappa', recall_cols)                              # draw / legend order
   series_col <- c('black', 'grey40', rec_col)
   series_pch <- c(19, 1, rep(2, length(recall_cols)))
   series_lty <- c(1, 2, rep(3, length(recall_cols)))
   names(series_col) <- names(series_pch) <- names(series_lty) <- series_m

   K    <- length(series_m)                                                  # multiplicative jitter (log x) so bars don't overlap
   offs <- (seq_len(K) - (K + 1) / 2) * 0.015
   names(offs) <- series_m
   xj   <- function(m) agg$n_sites * (1 + offs[m])

   ebar <- function(m) {                                                     # +/-1 SE (or SD) bar at the series' jittered x
      e <- switch(error, se = agg[[paste0(m, '_se')]], sd = agg[[paste0(m, '_sd')]], none = NULL)
      if(!is.null(e))
         suppressWarnings(arrows(xj(m), agg[[m]] - e, xj(m), agg[[m]] + e,
                                 angle = 90, code = 3, length = 0.03, col = series_col[m]))
   }

   xlim <- range(agg$n_sites) * c(0.9, 1.12)
   plot(xj('ccr'), agg$ccr, type = 'b', pch = 19, ylim = c(0, 1), xlim = xlim, log = 'x',
        xlab = 'number of training sites (transects)', ylab = 'accuracy / recall',
        main = 'U-Net accuracy vs number of training sites', col = 'black')
   ebar('ccr')
   lines(xj('kappa'), agg$kappa, type = 'b', pch = 1, lty = 2, col = 'grey40')
   for(m in recall_cols) {                                                    # each per-class recall + its own error bars
      lines(xj(m), agg[[m]], type = 'b', pch = 2, lty = 3, col = series_col[m])
      ebar(m)
   }

   if(any(is.infinite(agg$count_req))) {                                      # mark the all-sites anchor
      xa <- agg$n_sites[is.infinite(agg$count_req)][1]
      abline(v = xa, lty = 3, col = 'grey70')
      text(xa, 0.02, 'all sites', srt = 90, adj = c(0, -0.3), cex = 0.7, col = 'grey40')
   }

   ccr_lab <- if(error == 'none') 'CCR' else sprintf('CCR (+/-1 %s)', toupper(error))
   legend('bottomright', c(ccr_lab, 'Kappa', recall_cols),
          pch = series_pch, lty = series_lty, col = series_col, bty = 'n')

   invisible(agg[order(agg$n_sites), ])
}
