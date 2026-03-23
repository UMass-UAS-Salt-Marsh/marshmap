#' Prepare map patches for U-Net prediction
#'
#' Tiles the full ortho extent (or a clipped region) into overlapping patches
#' for wall-to-wall prediction. Patches are saved as numpy arrays alongside
#' a CSV of spatial origins for later reassembly.
#'
#' @param fitid Fit id in the fits database. The model name is resolved from
#'   the database. Provide either `fitid` or `model`, not both.
#' @param model The model name (base name of the prep `.yml` in `<pars>/unet/`).
#'   Use this to prep map patches for a model that may have multiple training
#'   runs, or before any training has been registered in the fits database.
#' @param clip Optional clip extent, vector of `xmin`, `xmax`, `ymin`, `ymax`.
#'   If NULL, tiles the full ortho extent.
#' @param resources Slurm launch resources. See \link[slurmcollie]{launch}.
#' @param local If TRUE, run locally; otherwise, spawn a batch run on Unity
#' @param trap If TRUE, trap errors in local mode
#' @param comment Optional slurmcollie comment
#' @importFrom slurmcollie launch get_resources
#' @export


unet_prep_map <- function(fitid = NULL, model = NULL, clip = NULL, 
                          resources = NULL, local = FALSE, trap = TRUE, 
                          comment = NULL) {
   
   
   # ----- Resolve model name -----
   if(!is.null(fitid) && !is.null(model))
      stop('Provide either fitid or model, not both')
   
   if(is.null(fitid) && is.null(model))
      stop('Must provide either fitid or model')
   
   if(!is.null(fitid)) {
      load_database('fdb')
      fitrow <- which(the$fdb$id == fitid)
      if(length(fitrow) == 0)
         stop('Fit id ', fitid, ' not found in fits database')
      model <- the$fdb$name[fitrow]
   }
   
   
   resources <- get_resources(resources, list(
      ncpus = 1,
      memory = 180,
      walltime = '04:00:00'
   ))
   
   
   if(is.null(comment))
      comment <- paste0('unet_prep_map ', model,
                        if(!is.null(fitid)) paste0(' (fitid: ', fitid, ')') else '')
   
   
   launch('do_unet_prep_map', reps = model, repname = 'model', 
          moreargs = list(clip = clip),
          local = local, trap = trap, resources = resources, comment = comment)
}
