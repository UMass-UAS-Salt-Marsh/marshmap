#' Finish fit run
#' 
#' Finish a fit run:
#'  - Populate fits database with `slurmcollie` stats
#'  - and with info from `zz_<id>_fit.RDS`, written by `do_fit`
#'  - Copy the log file to the models directory
#' 
#' @param jobid Job id to finish for
#' @param status Job status
#' @importFrom slurmcollie logfile slu
#' @export


fit_finish <- function(jobid, status) {
   
   
   jrow <- match(jobid, slu$jdb$jobid)                            # find our row in slurmcollie jobs database (it's been loaded by info)
   
   load_database('fdb')
   frow <- match(slu$jdb$callerid[jrow], the$fdb$id)              # find our row in the fit database
   
   
   if(is.na(frow)) {
      message('Fit id ', slu$jdb$callerid[jrow], ' (job ', jobid, ') is missing from the fits database')
      return()
   }
   
   
   # Copy log file
   if(!dir.exists(the$modelsdir))
      dir.create(the$modelsdir, recursive = TRUE, showWarnings = FALSE)
   sink <- file.copy(logfile(jobid)$done, 
                     file.path(the$modelsdir, 
                               paste0('fit_', the$fdb$id[frow], '.log')),
                     overwrite = TRUE)
   
   
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
   
   if(the$fdb$success[frow]) {                                    # If job was successful, get stuff from zz_<id>_fit.RDS, written by do_fit
      
      the$fdb$error[frow] <- FALSE                                #    since we're here, we know there wasn't an error
      the$fdb$message <- ''                                       #    and no error message
      
      f <- file.path(the$modelsdir, paste0('zz_', slu$jdb$callerid[jrow], '_fit.RDS'))
      if(file.exists(f)) {                                        #    if temp fit file exists,
         x <- readRDS(f)
         
         the$fdb$vars[frow] <- x$vars                             # number of variables
         the$fdb$cases[frow] <- x$cases                           # sample size   
         the$fdb$holdout[frow] <- x$holdout                       # holdout sample size
         the$fdb$CCR[frow] <- x$CCR                               # correct classification rate
         the$fdb$kappa[frow] <- x$kappa                           # Kappa
         
         the$fdb$model[frow] <- x$model                           # user-specified model, set in do_fit, resolved in fit_finish
         the$fdb$full_model[frow] <- x$full_model                 # complete model specification, set in do_fit, resolved in fit_finish
         the$fdb$hyper[frow] <- x$hyper                           # hyperparameters, set in do_fit, resolved in fit_finish
      }
   }
   
   
   save_database('fdb')                                           # save the database
   
   if(the$fdb$success[frow])                                      # If the job was successful,
      unlink(f)                                                   #    it's now safe to delete the temporary file from do_fit
}