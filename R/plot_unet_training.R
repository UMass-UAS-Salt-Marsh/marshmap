#' Plot U-Net training curves across cross-validations
#'
#' Reads per-CV training metrics CSVs, computes a smoothed cross-validation mean,
#' and saves a ggplot2 figure. Individual CV curves are shown in light pastel colors;
#' the smoothed mean is shown as a bold black line.
#'
#' @param all_metrics List of data frames, one per CV, as returned by reading each
#'   `training_metrics.csv`.
#' @param config List of configuration parameters (uses `config$window` for the
#'   half-width of the centered rolling-mean smoother; default 1 = no smoothing).
#' @param model_dir Directory where the output PNG will be saved.
#' @param site 3-letter site code (used only for the plot title).
#' @importFrom patchwork wrap_plots plot_annotation
#' @keywords internal


plot_unet_training <- function(all_metrics, config, model_dir, site) {

   
   window <- as.integer(if (!is.null(config$window)) config$window else 1L)
   n_cv   <- length(all_metrics)

   # Centered rolling mean (handles edges gracefully)
   roll_mean <- function(x, w) {
      if (w <= 1L) return(x)
      half <- w %/% 2L
      n <- length(x)
      vapply(seq_len(n), function(i) {
         mean(x[max(1L, i - half):min(n, i + half)], na.rm = TRUE)
      }, numeric(1))
   }

   # ── Combine CVs ──────────────────────────────────────────────────────────────
   df <- dplyr::bind_rows(
      lapply(seq_len(n_cv), function(i) {
         all_metrics[[i]]$cv <- factor(i)
         all_metrics[[i]]
      })
   )

   # Pastel palette: one colour per CV (up to 5)
   pastel_hex <- c('#FF9999', '#99BBFF', '#99FFAA', '#FFE066', '#CC99FF')
   cv_colors  <- setNames(pastel_hex[seq_len(n_cv)], as.character(seq_len(n_cv)))

   # ── Smoothed per-epoch mean across CVs ───────────────────────────────────────
   smooth <- df |>
      dplyr::group_by(.data$epoch) |>
      dplyr::summarise(
         train_loss = mean(.data$train_loss, na.rm = TRUE),
         val_ccr    = mean(.data$val_ccr,    na.rm = TRUE),
         test_ccr   = mean(.data$test_ccr,   na.rm = TRUE),
         .groups = 'drop'
      ) |>
      dplyr::arrange(.data$epoch) |>
      dplyr::mutate(
         train_loss_s = roll_mean(.data$train_loss, window),
         val_ccr_s    = roll_mean(.data$val_ccr,    window),
         test_ccr_s   = roll_mean(.data$test_ccr,   window),
      )

   has_val  <- any(!is.na(df$val_ccr))
   has_test <- any(!is.na(df$test_ccr))

   # ── Per-class CCR (long format) ──────────────────────────────────────────────
   class_cols <- grep('^test_ccr_class', names(df), value = TRUE)
   has_class  <- length(class_cols) > 0 && has_test

   if (has_class) {
      df_class <- tidyr::pivot_longer(
         df,
         cols      = dplyr::all_of(class_cols),
         names_to  = 'class',
         values_to = 'class_ccr',
         names_prefix = 'test_ccr_class'
      ) |>
         dplyr::filter(!is.na(.data$class_ccr))

      smooth_class <- df_class |>
         dplyr::group_by(.data$epoch, .data$class) |>
         dplyr::summarise(class_ccr = mean(.data$class_ccr, na.rm = TRUE), .groups = 'drop') |>
         dplyr::arrange(.data$class, .data$epoch) |>
         dplyr::group_by(.data$class) |>
         dplyr::mutate(class_ccr_s = roll_mean(.data$class_ccr, window)) |>
         dplyr::ungroup()
   }

   # ── Panel 1: Train loss ───────────────────────────────────────────────────────
   p_loss <- ggplot2::ggplot() +
      ggplot2::geom_line(
         data    = df,
         mapping = ggplot2::aes(x = .data$epoch, y = .data$train_loss,
                                group = .data$cv, color = .data$cv),
         alpha   = 0.4, linewidth = 0.6
      ) +
      ggplot2::geom_line(
         data    = smooth,
         mapping = ggplot2::aes(x = .data$epoch, y = .data$train_loss_s),
         color   = 'black', linewidth = 1.2
      ) +
      ggplot2::scale_color_manual(values = cv_colors, name = 'CV') +
      ggplot2::labs(x = 'Epoch', y = 'Train Loss', title = 'Training Loss') +
      ggplot2::theme_bw()

   # ── Panel 2: Overall CCR (test; val overlaid if present) ─────────────────────
   p_ccr <- ggplot2::ggplot()

   if (has_test) {
      df_test     <- df[!is.na(df$test_ccr), ]
      smooth_test <- smooth[!is.na(smooth$test_ccr_s), ]
      p_ccr <- p_ccr +
         ggplot2::geom_line(
            data    = df_test,
            mapping = ggplot2::aes(x = .data$epoch, y = .data$test_ccr * 100,
                                   group = .data$cv, color = .data$cv),
            alpha   = 0.4, linewidth = 0.6
         ) +
         ggplot2::geom_line(
            data    = smooth_test,
            mapping = ggplot2::aes(x = .data$epoch, y = .data$test_ccr_s * 100),
            color   = 'black', linewidth = 1.2
         )
   }

   if (has_val) {
      df_val     <- df[!is.na(df$val_ccr), ]
      smooth_val <- smooth[!is.na(smooth$val_ccr_s), ]
      p_ccr <- p_ccr +
         ggplot2::geom_line(
            data    = df_val,
            mapping = ggplot2::aes(x = .data$epoch, y = .data$val_ccr * 100,
                                   group = .data$cv, color = .data$cv),
            alpha   = 0.25, linewidth = 0.5, linetype = 'dashed'
         ) +
         ggplot2::geom_line(
            data    = smooth_val,
            mapping = ggplot2::aes(x = .data$epoch, y = .data$val_ccr_s * 100),
            color   = 'steelblue', linewidth = 1.0, linetype = 'dashed'
         )
   }

   ccr_title <- dplyr::case_when(
      has_test && has_val ~ 'CCR (solid=test, dashed=val)',
      has_test             ~ 'Test CCR',
      has_val              ~ 'Validation CCR',
      TRUE                 ~ 'CCR'
   )
   p_ccr <- p_ccr +
      ggplot2::scale_color_manual(values = cv_colors, name = 'CV') +
      ggplot2::labs(x = 'Epoch', y = 'CCR (%)', title = ccr_title) +
      ggplot2::ylim(0, 100) +
      ggplot2::theme_bw()

   # ── Panel 3: Per-class CCR ────────────────────────────────────────────────────
   if (has_class) {
      # Choose distinct colours for classes (different from CV pastels)
      n_classes    <- length(class_cols)
      class_colors <- scales::hue_pal()(n_classes)
      names(class_colors) <- sub('test_ccr_class', '', class_cols)

      p_class <- ggplot2::ggplot() +
         ggplot2::geom_line(
            data    = df_class,
            mapping = ggplot2::aes(x = .data$epoch, y = .data$class_ccr * 100,
                                   group = interaction(.data$cv, .data$class),
                                   color = .data$class),
            alpha = 0.25, linewidth = 0.5
         ) +
         ggplot2::geom_line(
            data    = smooth_class,
            mapping = ggplot2::aes(x = .data$epoch, y = .data$class_ccr_s * 100,
                                   color = .data$class),
            linewidth = 1.1
         ) +
         ggplot2::scale_color_manual(values = class_colors, name = 'Class') +
         ggplot2::labs(x = 'Epoch', y = 'CCR (%)', title = 'Per-Class Test CCR') +
         ggplot2::ylim(0, 100) +
         ggplot2::theme_bw()
   }

   # ── Combine and save ──────────────────────────────────────────────────────────
   if (has_class) {
      combined <- patchwork::wrap_plots(p_loss, p_ccr, p_class, ncol = 3)
      plot_w   <- 18
   } else {
      combined <- patchwork::wrap_plots(p_loss, p_ccr, ncol = 2)
      plot_w   <- 12
   }

   combined <- combined +
      patchwork::plot_annotation(
         title = paste0('U-Net training: ', site),
         theme = ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5))
      )

   plot_path <- file.path(model_dir, 'training_curves.png')
   ggplot2::ggsave(plot_path, combined, width = plot_w, height = 5, dpi = 150)
   message('Training curves saved to: ', plot_path)
}
