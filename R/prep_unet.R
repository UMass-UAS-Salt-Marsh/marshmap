#' Pre-process data for U-Net
#' 
#' Creates numpy arrays ready for fitting in U-Net. Result files are placed in `<site>/unet/<model>`.
#' 
#' Try this to test:
#'    `prep_unet('unet01', local = TRUE)`
#' 
#' @param model The model name, which is also the name of a `.yml` parameter file in the `pars` 
#'    directory. This file must contain the following:
#'    - years: the year(s) of field data to fit
#'    - orthos: file names of all orthophotos to include
#'    - patch: size in pixels
#'    - depth: number of of downsampling stages
#'    - classes: vector of target classes
#'    - holdout: holdout set to use (uses bypoly<holdout>, classes 1 and 6). Holdout sets are
#'      created by `gather` to yield at least 20% of separate polys. There are 5 sets to choose from.
#'    - overlap: Proportion overlap of patches
#'    - upscale: number of cells to upscale (default = 1). Use 3 to upscale to 3x3, 5 for 5x5, etc.
#'    - smooth: number of cells to include in moving window mean (default = 1). Use 3 to smooth to 3x3, etc.
#' @param save_gis If TRUE, saves GIS data for assessment and debugging
#' @param resources Slurm launch resources. See \link[slurmcollie]{launch}. These take priority
#'    over the function's defaults.
#' @param local If TRUE, run locally; otherwise, spawn a batch run on Unity
#' @param trap If TRUE, trap errors in local mode; if FALSE, use normal R error handling. Use this
#'    for debugging. If you get unrecovered errors, the job won't be added to the jobs database. Has
#'    no effect if local = FALSE.
#' @param comment Optional slurmcollie comment
#' @importFrom slurmcollie launch get_resources
#' @export


prep_unet <- function(model, save_gis = FALSE, resources = NULL, local = FALSE, trap = TRUE, comment = NULL) {
   
   
   resources <- get_resources(resources, list(
      ncpus = 1,
      memory = 180,
      walltime = '10:00:00'
   ))
   
   
   if(is.null(comment))
      comment <- paste0('prep_unet ', model)
   
   
   launch('do_prep_unet', reps = model, repname = 'model', moreargs = list(save_gis = save_gis),
          local = local, trap = trap, resources = resources, comment = comment)
}