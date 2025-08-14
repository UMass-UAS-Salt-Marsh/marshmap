#' Finish fit run
#' 
#' Finish a fit run:
#'  - Populate fits database with `slurmcollie` stats
#'  - and with info from `zz<id>_fit.RDS`, written by `do_fit`
#'  - Copy the log file to the models directory
#' 
#' @param jobid Job id to finish for
#' @param status Job status
#' @importFrom slurmcollie logfile slu
#' @keywords internal


fit_finish <- function(jobid, status) {

   
   jrow <- match(jobid, slu$jdb$jobid)                            # find our row in slurmcollie jobs database (it's been loaded by info)
   
   load_database('fdb')
   frow <- match(slu$jdb$callerid, the$fdb$id)                    # find our row in the fit database
   
   
   # Get stuff from slurmcollie jobs database
   the$fdb$success[frow] <- slu$jdb$status[jrow] == 'finished'    # run success
   the$fdb$status[frow] <- slu$jdb$status[jrow]                   # final slurmcollie status
   the$fdb$error[frow] <- slu$jdb$error[jrow]                     # TRUE if error
   the$fdb$message[frow] <- slu$jdb$message[jrow]                 # error message if any
   the$fdb$cores[frow] <- slu$jdb$cores[jrow]                     # cores requested
   the$fdb$cpu[frow] <- slu$jdb$cpu[jrow]                         # CPU time
   the$fdb$cpu_pct[frow] <- slu$jdb$cpu_pct[jrow]                 # percent CPU used
   the$fdb$mem_req[frow] <- slu$jdb$mem_req[jrow]                 # memory requested (GB)
   the$fdb$mem_gb[frow] <- slu$jdb$mem_gb[jrow]                   # memory used (GB)
   the$fdb$walltime[frow] <- slu$jdb$walltime[jrow]               # elapsed run time
   
   
   if(the$jdb$success[frow]) {                                    # If job was successful, get stuff from zz<id>_fit.RDS
      x <- readRDS(file.path(the$modeldir, paste0('zz', slu$jdb$callerid, '_fit.RDS')))
      
      the$fdb$model[frow] <- x$model                              # user-specified model, set in do_fit, resolved in fit_finish
      the$fdb$full_model[frow] <- x$full_model                    # complete model specification, set in do_fit, resolved in fit_finish
      the$fdb$hyper[frow] <- x$hyper                              # hyperparameters, set in do_fit, resolved in fit_finish
      
      the$fdb$CCR[frow] <- x$CCR                                  # correct classification rate
      the$fdb$kappa[frow] <- x$kappa                              # Kappa
      the$fdb$F1[frow] <- x$F1                                    # F1 statistic
   }
   
   
   # Copy log file
   if(!dir.exists(the$modelsdir))
      dir.create(the$modelsdir, recursive = TRUE, showWarnings = FALSE)
   sink <- file.copy(logfile(jobid)$done, 
                     file.path(the$modelsdir, 
                               paste0('fit_', the$fdb$id[frow], '.log')),
                     overwrite = TRUE)
}