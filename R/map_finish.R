#' Finish do_map run, updating maps database
#' 
#' @param jobid slurmcollie job id
#' @param status Job status
#' @export


map_finish <- function(jobid, status) {
   
   
   message('Finishing map run with jobid ', jobid, ' and status "', status, '"...')      # TEMP FOR DEBUGGING
   
   
   
   jrow <- match(jobid, slu$jdb$jobid)                            # find our row in slurmcollie jobs database (it's been loaded by info)
   
   load_database('mdb')
   mrow <- match(slu$jdb$callerid[jrow], the$mdb$mapid)           # find our row in the map database
   
   if(is.na(mrow))
      stop('Map id ', slu$jdb$callerid[jrow], ' (job ', jobid, ') is missing from the maps database')
   
   
   dir <- resolve_dir(the$mapsdir, the$mdb$site[mrow])            # maps directory for this site
   
   # Copy log file
   if(!dir.exists(dir))
      dir.create(dir, recursive = TRUE, showWarnings = FALSE)
   sink <- file.copy(logfile(jobid)$done, 
                     file.path(dir, paste0('map_', the$mdb$id[mrow], '.log')),
                     overwrite = TRUE)
   
   
   # Get stuff from slurmcollie jobs database
   the$mdb$success[mrow] <- slu$jdb$status[jrow] == 'finished'    # run success
   the$mdb$status[mrow] <- slu$jdb$status[jrow]                   # final slurmcollie status
   the$mdb$error[mrow] <- slu$jdb$error[jrow]                     # TRUE if error
   the$mdb$message[mrow] <- slu$jdb$message[jrow]                 # error message if any
   the$mdb$cores[mrow] <- slu$jdb$cores[jrow]                     # cores requested
   the$mdb$cpu[mrow] <- slu$jdb$cpu[jrow]                         # CPU time
   the$mdb$cpu_pct[mrow] <- slu$jdb$cpu_pct[jrow]                 # percent CPU used
   the$mdb$mem_req[mrow] <- slu$jdb$mem_req[jrow]                 # memory requested (GB)
   the$mdb$mem_gb[mrow] <- slu$jdb$mem_gb[jrow]                   # memory used (GB)
   the$mdb$walltime[mrow] <- slu$jdb$walltime[jrow]               # elapsed run time
   
   
   if(the$mdb$success[mrow]) {                                    # If job was successful, get stuff from zz_<id>_map.RDS, written by do_map
      
      the$mdb$error[mrow] <- FALSE                                #    since we're here, we know there wasn't an error
      the$mdb$message <- ''                                       #    and no error message
      
      x <- readRDS(f <- file.path(dir, paste0('zz_', slu$jdb$callerid[jrow], '_map.RDS')))
      
      the$mdb$mpix <- x$mpix                                      # non-missing megapixels in result
   }
   
   save_database('mdb')                                           # save the database
   
   if(the$mdb$success[mrow])                                      # If the job was successful,
      unlink(f)                                                   #    it's now safe to delete the temporary file from do_map
   
   ### NOW WE WANT TO WRITE file.path(dir, paste0(file_path_sans_extension(result), '_metadata.txt')
   ### with date and time, result, mapid, fitid, comments, and model assessment
   ### This is a human-readable file for posterity; it should travel with the map
}