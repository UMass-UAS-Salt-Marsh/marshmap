#' Finish train run
#'
#' Finish a U-Net train run:
#'  - Populate fits database with `slurmcollie` stats
#'  - and with info from `zz_<id>_train.RDS`, written by `do_train`
#'  - Copy the log file to the models directory as `fit_<id>.log`
#'  - Copy summary to `fit_<id>_summary.txt`
#'  - Copy training curves to `fit_<id>_training_curves.png` (if present)
#'
#' @param jobid Job id to finish for
#' @param status Job status
#' @importFrom slurmcollie logfile slu
#' @export


train_finish <- function(jobid, status) {


   jrow <- match(jobid, slu$jdb$jobid)                            # find our row in slurmcollie jobs database

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
   the$fdb$success[frow]  <- slu$jdb$status[jrow] == 'finished'   # run success
   the$fdb$status[frow]   <- slu$jdb$status[jrow]                 # final slurmcollie status
   the$fdb$error[frow]    <- slu$jdb$error[jrow]                  # TRUE if error
   the$fdb$message[frow]  <- slu$jdb$message[jrow]                # error message if any
   the$fdb$cores[frow]    <- slu$jdb$cores[jrow]                  # cores requested
   the$fdb$cpu[frow]      <- slu$jdb$cpu[jrow]                    # CPU time
   the$fdb$cpu_pct[frow]  <- slu$jdb$cpu_pct[jrow]                # percent CPU used
   the$fdb$mem_req[frow]  <- slu$jdb$mem_req[jrow]                # memory requested (GB)
   the$fdb$mem_gb[frow]   <- slu$jdb$mem_gb[jrow]                 # memory used (GB)
   the$fdb$walltime[frow] <- slu$jdb$walltime[jrow]               # elapsed run time
   the$fdb$gpu[frow]      <- slu$jdb$gpu[jrow]                    # GPU(s) used
   the$fdb$gpu_pct[frow]  <- slu$jdb$gpu_pct[jrow]                # percent GPU utilization
   the$fdb$gpu_mem[frow]  <- slu$jdb$gpu_mem_gb[jrow]             # GPU memory used (GB)

   if(the$fdb$success[frow]) {                                    # If job was successful, get stuff from zz_<id>_train.RDS
      the$fdb$error[frow]   <- FALSE
      the$fdb$message[frow] <- ''

      f <- file.path(the$modelsdir, paste0('zz_', slu$jdb$callerid[jrow], '_train.RDS'))
      if(file.exists(f)) {
         x <- readRDS(f)

         the$fdb$CCR[frow]     <- x$CCR
         the$fdb$kappa[frow]   <- x$kappa
         the$fdb$vars[frow]    <- x$vars
         the$fdb$holdout[frow] <- x$holdout
         the$fdb$hyper[frow]   <- x$hyper

         # Copy summary and training curves to models directory
         summary_src <- file.path(x$fit_dir, 'summary.txt')
         if(file.exists(summary_src))
            file.copy(summary_src,
                      file.path(the$modelsdir, paste0('fit_', the$fdb$id[frow], '_summary.txt')),
                      overwrite = TRUE)

         curves_src <- file.path(x$fit_dir, 'training_curves.png')
         if(file.exists(curves_src))
            file.copy(curves_src,
                      file.path(the$modelsdir, paste0('fit_', the$fdb$id[frow], '_training_curves.png')),
                      overwrite = TRUE)
      }
   }


   save_database('fdb')                                           # save the database

   if(the$fdb$success[frow])                                      # If the job was successful,
      unlink(f)                                                   #    it's now safe to delete the temporary file from do_train
}
