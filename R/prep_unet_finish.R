#' Finish prep_unet run
#'
#' Finish a U-Net data preparation run:
#'  - Copy the log file to the unet model directory as `prep_<model>.log`
#'
#' @param jobid Job id to finish for
#' @param status Job status
#' @importFrom slurmcollie logfile slu
#' @importFrom yaml read_yaml
#' @export


prep_unet_finish <- function(jobid, status) {


   jrow  <- match(jobid, slu$jdb$jobid)                            # find our row in slurmcollie jobs database
   model <- slu$jdb$rep[jrow]                                      # model name was passed as rep

   config    <- read_yaml(file.path(the$parsdir, 'unet', paste0(model, '.yml')))
   model_dir <- file.path(resolve_dir(the$unetdir, config$site), model)

   if(!dir.exists(model_dir))
      dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)

   file.copy(logfile(jobid)$done,
             file.path(model_dir, paste0('prep_', model, '.log')),
             overwrite = TRUE)
}
