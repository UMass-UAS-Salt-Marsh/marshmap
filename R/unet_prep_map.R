#' Prepare map patches for U-Net prediction
#'
#' Tiles the full ortho extent (or a clipped region) into overlapping patches
#' for wall-to-wall prediction. Patches are saved as numpy arrays alongside
#' a CSV of spatial origins for later reassembly.
#'
#' @param model The model name (base name of the prep `.yml` in `<pars>/unet/`)
#' @param clip Optional clip extent, vector of `xmin`, `xmax`, `ymin`, `ymax`.
#'   If NULL, tiles the full ortho extent.
#' @param resources Slurm launch resources. See \link[slurmcollie]{launch}.
#' @param local If TRUE, run locally; otherwise, spawn a batch run on Unity
#' @param trap If TRUE, trap errors in local mode
#' @param comment Optional slurmcollie comment
#' @importFrom slurmcollie launch get_resources
#' @export


unet_prep_map <- function(model, clip = NULL, resources = NULL, 
                          local = FALSE, trap = TRUE, comment = NULL) {
   
   
   resources <- get_resources(resources, list(
      ncpus = 1,
      memory = 180,
      walltime = '04:00:00'
   ))
   
   
   if(is.null(comment))
      comment <- paste0('unet_prep_map ', model)
   
   
   launch('do_unet_prep_map', reps = model, repname = 'model', 
          moreargs = list(clip = clip),
          local = local, trap = trap, resources = resources, comment = comment)
}
