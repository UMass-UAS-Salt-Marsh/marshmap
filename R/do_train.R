#' Train and assess U-Net model
#' 
#' Train a U-Net model. Result files are placed in `<site>/unet/<model>`.
#' 
#' @param model The base name of a `.yml` file in `<pars>/unet/` with model parameters. This
#'    file contains parameters used in data prep as well as training. Note that `prep_unet` 
#'    must be run after changing any of these parameters. The `model` file must contain the 
#'    following:
#'    - site: the three-letter site code
#'    - years: the year(s) of field data to fit
#'    - orthos: file names of all orthophotos to include
#'    - patch: size in pixels
#'    - depth: number of of downsampling stages
#'    - classes: vector of target classes (in original classification)
#'    - holdout_col: holdout set to use (uses bypoly<holdout>). Holdout sets are created by
#'      `gather`, numbering each poly from 1 to 10, repeating if necessary. There are 5 sets to 
#'      choose from.
#'    - cv: number of cross-validations. Use 1 for a single model, up to 5 for five-fold 
#'      cross-validation. Cross-validations are systematic, not random. Since there are only 10 
#'      sets in each bypoly, the number of cross-validations is limited by the values of val 
#'      and test. 
#'    - val: validation polys from `holdout_col`. Use NULL to skip validation, or a vector of 
#'      the validation polys for the first cross-validation (these will be incremented for
#'      subsequent validations). For 20% validation holdout, use `val = c(1, 6)`. This will use
#'      `bypoly01 %in% c(1,6)`` for the first cross-validation, `c(2, 7)` for the second, and so 
#'      on. 
#'    - test: test polys from `holdout_col`, as with `val`.
#'    - overlap: Proportion overlap of patches
#'    - upscale: number of cells to upscale (default = 1). Use 3 to upscale to 3x3, 5 for 5x5, etc.
#'    - smooth: number of cells to include in moving window mean (default = 1). Use 3 to smooth to 3x3, etc.
#' @param train The base name of a `.yml` file in `<pars>/unet/` with training parameters. 
#'    If present, this overrides any overlapping parameters in `model`. This file contains parameters used 
#'    only in the training phase. The following must be present either in the `model` or `train` file:
#'    - n_epochs Number of training epochs
#'    - encoder_name. Pre-trained encoder to use. Choices include `resnet10`, `resnet18`, 
#'     `resnet34`, `resnet50`, `efficientnet-b0`, and others. The lower `restnet` 
#'     numbers have fewer parameters, so may be likely to result in more stable training.
#'    - encoder_weights. `imagenet` start with weights learned on ImageNet (natural images); 
#'      gives faster convergence, but might bias toward RGB patterns. NULL starts with random 
#'      initialization, thus learns everything from this dataset; no bias, but slower training. 
#'    - learning_rate Learning rate for optimizer
#'    - weight_decay. L2 regularization - penalizes large weights to prevent overfitting. 
#'      Higher values (1e-3) = stronger regularization. Lower values (1e-5) = weaker. 
#'    - batch_size. How many patches to process together. Larger (16, 32) uses parallelization
#'      on GPUs so trains faster, more stable gradients, uses more GPU memory. Smaller (4, 8) gives
#'      noisier gradients (good regularization), less memory, better for small datasets. Use 8; if
#'      overfitting is a problem, try 4.
#'    - gradient_clip_max_norm. Prevents exploding gradients by capping gradient magnitude. 
#'      Range: 0.5 (aggressive clipping) to 5.0 (gentle); start with 1.0.
#'    - use_ordinal If TRUE, use ordinal regression U-Net
#'    - test_interval Evaluate test CCR every this many epochs (default 1 = every epoch). The
#'      last epoch is always evaluated. Test results are shown in plots but never used to select
#'      the model.
#'    - plot_curves If TRUE (default), produce ggplot2 training-curve PNG in `model_dir`.
#'    - window Half-width (in epochs) of the centered rolling-mean smoother applied to the
#'      cross-validation mean curve before plotting (default 1 = no smoothing).
#' @param resources Slurm launch resources. See \link[slurmcollie]{launch}. These take priority
#'    over the function's defaults.
#' @param local If TRUE, run locally; otherwise, spawn a batch run on Unity
#' @param trap If TRUE, trap errors in local mode; if FALSE, use normal R error handling. Use this
#'    for debugging. If you get unrecovered errors, the job won't be added to the jobs database. Has
#'    no effect if local = FALSE.
#' @param comment Optional slurmcollie comment
#' @returns Invisibly: list with `confusion_matrix` (combined caret CM across all CVs) and
#'   `cv_ccr` (numeric vector of per-CV test CCR).
#' @import reticulate
#' @export


do_train <- function(model, train) {


   config <- read_yaml(file.path(the$parsdir, 'unet', paste0(model, '.yml')))       # read parameters from model
   if(!is.null(train)) {                                                            # and train, which takes priority
      config <- modifyList(config,
                           read_yaml(file.path(the$parsdir, 'unet', paste0(train, '.yml'))))
      message('Training file is ', paste0(train, '.yml'))
   }


   # Source the Python training script
   message('Sourcing Python code & initializing...')
   source_python("inst/python/train_unet.py")

   model_dir      <- file.path(resolve_dir(the$unetdir, config$site), model)
   all_metrics    <- vector('list', config$cv)                                      # training_metrics.csv per CV
   all_preds      <- list()                                                         # prediction factors across CVs
   all_labels_all <- list()                                                         # label factors across CVs
   cv_ccr         <- numeric(config$cv)                                             # final test CCR per CV

   for(i in seq_len(config$cv)) {                                                   # For each cross-validation iteration,
      data_dir   <- file.path(model_dir, paste0('set', i))
      output_dir <- file.path(data_dir, 'models')

      message('************ Cross-validation iteration ', i, ' of ', config$cv, ' ************')

      train_unet(
         site                  = config$site,
         data_dir              = data_dir,
         output_dir            = output_dir,
         use_ordinal           = config$use_ordinal,
         original_classes      = as.integer(config$classes),
         num_classes           = length(config$classes),
         encoder_name          = config$encoder_name,
         encoder_weights       = config$encoder_weights,
         learning_rate         = config$learning_rate,
         weight_decay          = config$weight_decay,
         n_epochs              = as.integer(config$n_epochs),
         batch_size            = as.integer(config$batch_size),
         gradient_clip_max_norm = config$gradient_clip_max_norm,
         test_interval         = as.integer(if (!is.null(config$test_interval)) config$test_interval else 1L)
      )

      # Read metrics CSV for later plotting
      metrics_path     <- file.path(output_dir, 'training_metrics.csv')
      all_metrics[[i]] <- read.csv(metrics_path, na.strings = c('', 'NA'))

      # Predict on test set
      message('Predicting on test set for CV ', i, '...')
      model_file   <- file.path(output_dir, paste0('unet_', config$site, '_best.pth'))
      pred_results <- unet_predict(model_file, data_dir, config$site, dataset = 'test')

      cv_ccr[i]         <- mean(pred_results$predictions == pred_results$labels)
      all_preds[[i]]    <- pred_results$predictions
      all_labels_all[[i]] <- pred_results$labels

      message(sprintf('   CV %d test CCR: %.2f%%', i, cv_ccr[i] * 100))
      message('')
   }


   # ── Final summary ──────────────────────────────────────────────────────────────
   message('\n', strrep('=', 60))
   message('Final test CCR per cross-validation:')
   for(i in seq_len(config$cv))
      message(sprintf('  CV %d: %.2f%%', i, cv_ccr[i] * 100))
   message(sprintf('  Mean: %.2f%%', mean(cv_ccr) * 100))

   # Combined confusion matrix (sum across all CVs)
   combined_preds  <- do.call(c, all_preds)
   combined_labels <- do.call(c, all_labels_all)
   cm <- unet_confusion_matrix(list(predictions = combined_preds, labels = combined_labels))
   print(cm)

   # Save confusion matrix
   cm_path <- file.path(model_dir, 'confusion_matrix.rds')
   saveRDS(cm, cm_path)
   message('Confusion matrix saved to: ', cm_path)


   # ── Plots ─────────────────────────────────────────────────────────────────────
   if (isTRUE(config$plot_curves)) {
      plot_unet_training(all_metrics, config, model_dir, config$site)
   }


   invisible(list(confusion_matrix = cm, cv_ccr = cv_ccr))
}