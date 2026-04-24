#' Finish unet_prep run
#'
#' Finish a U-Net data preparation run:
#'  - Copy the log file to the unet model directory as `prep_<model>.log`
#'
#' @param jobid Job id to finish for
#' @param status Job status
#' @importFrom slurmcollie logfile slu
#' @importFrom yaml read_yaml
#' @export


unet_prep_finish <- function(jobid, status) {


   jrow  <- match(jobid, slu$jdb$jobid)                            # find our row in slurmcollie jobs database
   model <- slu$jdb$rep[jrow]                                      # model name was passed as rep

   config_file <- file.path(the$parsdir, 'unet', paste0(model, '.yml'))
   if(!file.exists(config_file))
      return(invisible())

   config    <- read_yaml(config_file)
   config$site <- tolower(config$site)                   # we want to use lowercase for site names
   
   model_dir <- file.path(resolve_dir(the$unetdir, config$site), model)

   if(!dir.exists(model_dir))
      dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)

   file.copy(logfile(jobid)$done,
             file.path(model_dir, paste0('prep_', model, '.log')),
             overwrite = TRUE)
}
