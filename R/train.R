#' Train and assess U-Net model
#' 
#' Train a U-Net model. Result files are placed in `<site>/unet/<model>`.
#' 
#' @param model The base name of a `.yml` file in `<pars>/unet/` with model parameters. This
#'    file contains parameters used in data prep as well as training. Note that `unet_prep` 
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
#'    If present, this overrides parameters in `model`. This file contains parameters used only
#'    in the training phase. The following must be present either in the `model` or `train` file:
#'    - in_channels Number of input channels (8 for multispectral + NDVI + NDRE + DEM)
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
#'    - class_weighting. One of `none`, `freq`, or `sqrt`. If `none`, all classes will be given the 
#'      same weight; `freq` weights them by inverse frequency, and `sqrt` weights by the square
#'      root of the inverse frequency.
#'    - batch_size. How many patches to process together. Larger (16, 32) uses parallelization
#'      on GPUs so trains faster, more stable gradients, uses more GPU memory. Smaller (4, 8) gives
#'      noisier gradients (good regularization), less memory, better for small datasets. Use 8; if
#'      overfitting is a problem, try 4.
#'    - gradient_clip_max_norm. Prevents exploding gradients by capping gradient magnitude. 
#'      Range: 0.5 (aggressive clipping) to 5.0 (gentle); start with 1.0.
#'    - use_ordinal If TRUE, use ordinal regression U-Net      
#' @param result Name for this training run's result subdirectory. If NULL (default), automatically
#'    increments to the next available `fitNN` name (e.g. `"fit01"`, `"fit02"`). Specify explicitly
#'    to overwrite an existing run.
#' @param requirecuda If TRUE (default), abort immediately if CUDA is not available rather than
#'    silently falling back to CPU. Set to FALSE only for testing without a GPU.
#' @param resources Slurm launch resources. See \link[slurmcollie]{launch}. These take priority
#'    over the function's defaults. **Note that this function requires GPUs**. By default, it
#'    requests 1 L40S (preferred), but will accept V100 or RTX 2080 Ti. To specify only L40S, use
#'    `resources = list(constraint = 'l40s')`.
#' @param local If TRUE, run locally; otherwise, spawn a batch run on Unity
#' @param trap If TRUE, trap errors in local mode; if FALSE, use normal R error handling. Use this
#'    for debugging. If you get unrecovered errors, the job won't be added to the jobs database. Has
#'    no effect if local = FALSE.
#' @param comment Optional slurmcollie comment
#' @importFrom slurmcollie launch get_resources
#' @importFrom yaml read_yaml
#' @importFrom lubridate now
#' @export


train <- function(model, train = 'train', result = NULL, requirecuda = TRUE, resources = NULL, local = FALSE, trap = TRUE, comment = NULL) {


   resources <- get_resources(resources, list(
      ncpus = 1,
      ngpus = 1,
      constraint = 'l40s',                               # this can take a long time on alternative GPUs, so stick with l40s unless it queues forever
      # prefer_gpu = 'l40s',                             # L40S is best, but not worth waiting for
      # constraint = 'x86_64&[l40s|v100|2080ti]',        # alternative GPUs: V100 or RTX 2080 Ti
      # exclude = 'gypsum-gpu171',                       # TEMPORARY until it's fixed ***********************************************************
      partition.gpu = 'gpu-preempt,gpu',                 # GPUs for training. I'll start with 1, then move to 2; probably not worth using more
      # partition.gpu = 'gpu',                           # gpu-preempt times out in 4 hours!
      memory = 180,
      walltime = '04:00:00'                              # if setting >4 hrs, exclude gpu-preempt!
   ))


   if(is.null(comment))
      comment <- paste0('train ', model, ifelse(model == result, '', paste0(' / ', result)))


   config <- read_yaml(file.path(the$parsdir, 'unet', paste0(model, '.yml')))  # read model config to get site
   config$site <- tolower(config$site)                   # we want to use lowercase for site names

   if (is.null(result)) {
      model_dir <- file.path(resolve_dir(the$unetdir, config$site), model)
      existing  <- if (dir.exists(model_dir)) list.dirs(model_dir, full.names = FALSE, recursive = FALSE) else character(0)
      fit_nums  <- as.integer(sub('^fit0*(\\d+)$', '\\1', grep('^fit\\d+$', existing, value = TRUE)))
      result    <- sprintf('fit%02d', if (length(fit_nums) == 0) 1L else max(fit_nums) + 1L)
      message('Auto-assigned result directory: ', result)
   }

   load_database('fdb')                                  # Get fit database
   the$fdb[i <- nrow(the$fdb) + 1, ] <- NA               # add row to database

   the$fdb$id[i] <- the$last_fit_id + 1                  # model id
   comment <- paste0(comment, ' (fitid: ', the$fdb$id[i], ')')   # append fit id to comment
   the$fdb$name[i] <- model                              # model name
   the$fdb$site[i] <- config$site                        # site from model config
   the$fdb$method[i] <- 'unet'                           # modeling approach
   the$fdb$success[i] <- NA                              # run success; NA = not run yet
   the$fdb$status[i] <- ''                               # final slurmcollie status, resolved in train_finish
   the$fdb$error[i] <- NA                                # TRUE if error, resolved in train_finish
   the$fdb$message[i] <- ''                              # error message if any, resolved in train_finish
   the$fdb$cores[i] <- NA                                # cores requested, resolved in train_finish
   the$fdb$cpu[i] <- ''                                  # CPU time, resolved in train_finish
   the$fdb$cpu_pct[i] <- ''                              # percent CPU used, resolved in train_finish
   the$fdb$mem_req[i] <- NA                              # memory requested (GB), resolved in train_finish
   the$fdb$mem_gb[i] <- NA                               # memory used (GB), resolved in train_finish
   the$fdb$walltime[i] <- ''                             # elapsed run time, resolved in train_finish
   the$fdb$gpu[i] <- NA                                  # GPU(s) used, resolved in train_finish
   the$fdb$gpu_pct[i] <- NA                              # percent GPU utilization, resolved in train_finish
   the$fdb$gpu_mem[i] <- NA                              # GPU memory used (GB), resolved in train_finish
   the$fdb$CCR[i] <- NA                                  # correct classification rate, resolved in train_finish
   the$fdb$kappa[i] <- NA                                # Kappa, resolved in train_finish
   the$fdb$predicted[i] <- ''                            # name of predicted geoTIFF, added by map
   the$fdb$score[i] <- NA                                # subjective scoring field
   the$fdb$comment_launch[i] <- comment                  # comment set at launch
   the$fdb$comment_assess[i] <- ''                       # comment based on assessment
   the$fdb$comment_map[i] <- ''                          # comment based on final map
   the$fdb$call[i] <-
      gsub('\\"', '\'', gsub('[ ]+', ' ', paste(deparse(sys.calls()[[sys.nframe()]]), collapse = ' ')))
   the$fdb$model[i] <- paste0(model, '.yml')             # model yml file
   the$fdb$full_model[i] <- paste0(model, '.yml + ', train, '.yml')  # model + train yml
   the$fdb$datafile[i] <- paste0(model, '/', result)     # model/result subdirectory
   the$fdb$hyper[i] <- ''                                # hyperparameters, resolved in train_finish

   message('Fit id is ', the$fdb$id[i])
   the$last_fit_id <- the$fdb$id[i]                      # save last_fit_id

   the$fdb$launched[i] <- now()                          # date and time launched
   save_database('fdb')


   launch('do_train', reps = model, repname = 'model', moreargs = list(train = train, result = result, fitid = the$fdb$id[i], requirecuda = requirecuda),
          finish = 'train_finish', callerid = the$fdb$id[i],
          local = local, trap = trap, resources = resources, comment = comment)
}
