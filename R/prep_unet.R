#' Pre-process data for U-Net
#' 
#' Creates numpy arrays ready for fitting in U-Net. Result files are placed in `<site>/unet/<model>`.
#' 
#' @param model The model name, which is also the name of a `.yml` parameter file in the `pars` 
#'    directory. This file must contain the following:
#'    - year: the year to fit
#'    - orthos: portable names of all orthophotos to include
#'    - patch: size in pixels
#'    - depth: number of of downsampling stages
#'    - classes: vector of target classes
#'    - holdout: percent of data to hold out for validation
#' @param resources Slurm launch resources. See \link[slurmcollie]{launch}. These take priority
#' #'    over the function's defaults.
#' @param local If TRUE, run locally; otherwise, spawn a batch run on Unity
#' @param trap If TRUE, trap errors in local mode; if FALSE, use normal R error handling. Use this
#'   for debugging. If you get unrecovered errors, the job won't be added to the jobs database. Has
#'   no effect if local = FALSE.
#' @param comment Optional slurmcollie comment
#' @importFrom slurmcollie launch get_resources
#' @export


prep_unet <- function(model,  resources = NULL, local = FALSE, trap = TRUE, comment = NULL) {
   
   
   resources <- get_resources(resources, list(
      ncpus = 1,
      memory = 180,
      walltime = '10:00:00'
   ))
   
   
   if(is.null(comment))
      comment <- paste0('prep_unet ', model)
   
   
   launch('do_prep_unet', reps = model, repname = 'model', 
          local = local, trap = trap, resources = resources, comment = comment)
}