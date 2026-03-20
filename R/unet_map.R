#' Map with a trained U-Net model
#'
#' Produces a georeferenced GeoTIFF of predicted vegetation classes from a
#' trained U-Net model. Handles data prep, GPU prediction, and assembly.
#'
#' @param model The model name (base name of the prep `.yml`)
#' @param result The training result subdirectory (e.g., `'fit01'`). This is
#'   where the trained weights and config JSON live.
#' @param which Which model(s) to use for prediction. One of:
#'   - `'all'` (default): predict with all CV models and average probabilities
#'   - `'full'`: use a model trained on all data (must already exist in 
#'     `<result>/full/`)
#'   - An integer (1-5): use a specific cross-validation model
#' @param clip Optional clip extent, vector of `xmin`, `xmax`, `ymin`, `ymax`
#' @param write_probs If TRUE, also write per-class probability layers
#' @param resources Slurm launch resources. See \link[slurmcollie]{launch}.
#' @param local If TRUE, run locally; otherwise, spawn a batch run on Unity
#' @param trap If TRUE, trap errors in local mode
#' @param comment Optional slurmcollie comment
#' @importFrom slurmcollie launch get_resources
#' @importFrom yaml read_yaml
#' @export


unet_map <- function(model, result = 'fit01', which = 'all', clip = NULL,
                     write_probs = FALSE,
                     resources = NULL, local = FALSE, trap = TRUE, 
                     comment = NULL) {
   
   
   resources <- get_resources(resources, list(
      ncpus = 1,
      ngpus = 1,
      prefer_gpu = 'l40s',
      constraint = 'x86_64&[l40s|v100|2080ti]',
      partition.gpu = 'gpu-preempt,gpu',
      memory = 180,
      walltime = '02:00:00'
   ))
   
   
   # Validate 'which' parameter
   if(is.numeric(which)) {
      config <- read_yaml(file.path(the$parsdir, 'unet', paste0(model, '.yml')))
      if(which < 1 || which > config$cv)
         stop('which = ', which, ' is out of range; model has ', config$cv, ' CV folds')
   }
   else {
      if(!which %in% c('all', 'full'))
         stop('which must be "all", "full", or an integer CV fold number')
   }
   
   # If 'full', check that the full model exists
   if(identical(which, 'full')) {
      config <- read_yaml(file.path(the$parsdir, 'unet', paste0(model, '.yml')))
      full_dir <- file.path(resolve_dir(the$unetdir, config$site), model, result, 'full')
      if(!dir.exists(full_dir))
         stop('Full model not found at ', full_dir, 
              '. Train with full = TRUE first.')
   }
   
   
   if(is.null(comment))
      comment <- paste0('unet_map ', model, '/', result, ' (which=', which, ')')
   
   
   launch('do_unet_map', reps = model, repname = 'model', 
          moreargs = list(result = result, which = which, clip = clip,
                          write_probs = write_probs),
          local = local, trap = trap, resources = resources, comment = comment)
}
