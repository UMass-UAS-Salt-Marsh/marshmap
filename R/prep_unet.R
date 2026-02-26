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