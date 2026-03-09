#' Write summary.txt for a training run
#'
#' @param model Model name (base name of the .yml file)
#' @param train Train file name, or NULL
#' @param fit_dir Full path to the results directory
#' @param config Config list (merged model + train parameters)
#' @param cm caret confusionMatrix object (combined across all CVs)
#' @param cv_ccr Numeric vector of per-CV test CCR (0-1 scale)
#' @keywords internal


write_train_summary <- function(model, train, fit_dir, config, cm, cv_ccr) {

   classes    <- as.character(config$classes)
   overall_ccr <- cm$overall['Accuracy'] * 100
   kappa      <- cm$overall['Kappa']
   cv_range   <- sprintf('%d\u2013%d%%', round(min(cv_ccr) * 100), round(max(cv_ccr) * 100))

   # F1 per class (byClass is a matrix when >2 classes, named vector when 2)
   f1 <- if (is.matrix(cm$byClass)) cm$byClass[, 'F1'] else cm$byClass['F1']
   f1_str <- paste(sprintf('%.2f', f1), collapse = ' ')

   # Per-class CCR and pixel counts from confusion matrix table
   tbl        <- cm$table
   class_ccr  <- diag(tbl) / colSums(tbl) * 100   # sensitivity = per-class CCR
   class_npix <- colSums(tbl)                       # reference pixels per class

   # Poly counts (saved by do_prep_unet; use set 1 as representative)
   patches_dir    <- file.path(dirname(fit_dir), 'patches')
   poly_counts_path <- file.path(patches_dir, 'set1', 'poly_counts.rds')
   poly_line <- NULL
   if (file.exists(poly_counts_path)) {
      pc <- readRDS(poly_counts_path)
      fmt_counts <- function(tbl) paste(as.integer(tbl[classes]), collapse = '/')
      poly_line <- sprintf('   - polys: %s (train: %s, test: %s)',
                           fmt_counts(pc$total), fmt_counts(pc$train), fmt_counts(pc$test))
   } else {
      message('poly_counts.rds not found at ', poly_counts_path, '; polys line omitted from summary')
   }

   # Header
   header <- model
   if (!is.null(train))
      header <- paste(header, '/', train)
   lines <- c(
      paste(header, fit_dir),
      ''
   )

   # Site / classes / years / polys
   lines <- c(lines,
      sprintf('   - site: %s',         toupper(config$site)),
      sprintf('   - classes: [%s]',    paste(classes, collapse = ',')),
      sprintf('   - train years: %s',  paste(config$years, collapse = ' '))
   )
   if (!is.null(poly_line))
      lines <- c(lines, poly_line)
   lines <- c(lines, '')

   # Overall metrics
   lines <- c(lines,
      sprintf('   - CCR = %.1f, range = %s, Kappa = %.2f', overall_ccr, cv_range, kappa),
      sprintf('   - F1 for %s: %s', paste(classes, collapse = ' '), f1_str),
      ''
   )

   # Per-class CCR
   lines <- c(lines, '   - Per-class CCR:')
   for (k in seq_along(classes))
      lines <- c(lines,
         sprintf('      Class %s: %.2f%% (%s pixels)',
                 classes[k], class_ccr[k], format(class_npix[k], big.mark = ',')))

   # CCR per cross-validation
   lines <- c(lines, '', '   - CCR per cross-validation:')
   for (i in seq_along(cv_ccr))
      lines <- c(lines, sprintf('      CV %d: %.2f%%', i, cv_ccr[i] * 100))
   lines <- c(lines,
      sprintf('      Mean: %.2f%%', mean(cv_ccr) * 100),
      ''
   )

   # Normalized confusion matrix (% of total pixels)
   norm_tbl <- cm$table / sum(cm$table) * 100
   cls      <- colnames(norm_tbl)
   cell_w   <- max(nchar(sprintf('%.1f', norm_tbl)), nchar(cls)) + 2
   ref_hdr  <- paste0(strrep(' ', cell_w), 'Reference')
   col_hdr  <- paste0(strrep(' ', cell_w),
                      paste(formatC(cls, width = cell_w), collapse = ''))
   norm_rows <- character(nrow(norm_tbl))
   for (k in seq_len(nrow(norm_tbl)))
      norm_rows[k] <- paste0(
         formatC(rownames(norm_tbl)[k], width = cell_w),
         paste(formatC(sprintf('%.1f', norm_tbl[k, ]), width = cell_w), collapse = ''))
   lines <- c(lines,
      'Normalized Confusion Matrix (% of total pixels)',
      '', ref_hdr, col_hdr, norm_rows, '')

   # Confusion matrix (captured from print)
   lines <- c(lines, capture.output(print(cm)), '')

   # Parameters section
   reclass_val <- config$reclass
   if (is.null(reclass_val) || identical(reclass_val, ''))
      reclass_val <- 'NULL'

   encoder_weights_val <- config$encoder_weights
   if (is.null(encoder_weights_val))
      encoder_weights_val <- 'NULL'

   lines <- c(lines,
      'Parameters',
      '   - images:'
   )
   for (o in config$orthos)
      lines <- c(lines, paste0('      - ', o))

   param_pairs <- list(
      patch                  = config$patch,
      depth                  = config$depth,
      reclass                = reclass_val,
      holdout_col            = config$holdout_col,
      overlap                = config$overlap,
      cv                     = config$cv,
      n_epochs               = config$n_epochs,
      encoder_name           = config$encoder_name,
      encoder_weights        = encoder_weights_val,
      learning_rate          = config$learning_rate,
      weight_decay           = config$weight_decay,
      class_weighting        = sprintf("'%s'", config$class_weighting),
      batch_size             = config$batch_size,
      gradient_clip_max_norm = config$gradient_clip_max_norm,
      use_ordinal            = config$use_ordinal
   )

   lines <- c(lines, '')
   for (nm in names(param_pairs))
      lines <- c(lines, sprintf('   - %s: %s', nm, param_pairs[[nm]]))

   writeLines(lines)                                        # print to log
   summary_path <- file.path(fit_dir, 'summary.txt')
   writeLines(lines, summary_path)
   message('Summary written to: ', summary_path)

   invisible(lines)
}
