#' Finish sample run
#' 
#' Copies the log file to the samples directory
#' 
#' @param jobid Job ids to finish for
#' @param status Job status
#' @importFrom slurmcollie logfile slu
#' @keywords internal


sample_finish <- function(jobid, status) {
   
   
   site <- slu$jdb$rep[match(jobid, slu$jdb$jobid)]
   date <- stamp('2025-06-25_02-25', quiet = TRUE)
   path <- resolve_dir(the$samplesdir, tolower(site))
   if(!dir.exists(path))
      dir.create(path, recursive = TRUE, showWarnings = FALSE)
   t <- file.copy(logfile(jobid)$done, 
                  file.path(path, 
                            paste0('gather_', date(now(tzone = 'America/New_York')), '.log')),
                  overwrite = TRUE)
}