#' Purge selected fits from fits database
#' 
#' Cleans up the fits database of unwanted fits, as well as cleaning up sidecar
#' files. Purges are always reversible. 
#' 
#' Purged rows in the fits database are saved to `databases/purged/fdb_purged.RDS`, 
#' and associated files are moved to `databases/purged/`. Any stray fit sidecar 
#' files (fit_0000_extra.RDS, fit_0000.log, and zz_0000_fit.RDS) are also purged.
#' 
#' You can undo previous purges or unpurge specific fits with `undo`. Use 
#' `fitinfo(..., purged = TRUE)` to view purged fits.
#' 
#' If you're hurting for disk space, it's fair game to delete 
#' `databases/purged/fdb_purged.RDS` and files in `databases/purged/`. Doing so
#' will prevent you from recovering purged fits, of course.
#' 
#' @param rows Selected rows in the fits database. Use one of
#'  - an empty string doesn't purge any fits, but does purge stray fit files
#'  - a vector of `fitids` to purge those fits
#'  - a named list to filter fits. List items are `<field in fdb> = <value>`, 
#'    where `<value>` is a regex for character fields, or an actual value (or vector of 
#'    values) for logical or numeric fields.
#' @param failed If TRUE, all fits where `success` is `FALSE` or `NA` are purged.
#'    This is an alternative to specifying `rows`.
#' @param undo Undo previous purges. There is no time limit on undoing, and it doesn't
#'    matter whether you've run more fits since a purge. You may suppy either:
#'  - `undo = 'last'`, reverses the previous purge call, and the 
#'    database and associated files are restored. Call `fitpurge(undo = 'last')` repeatedly to roll 
#'    back farther. 
#'  - a vector of fit ids corresponding to previously purged fits.
#'    Note that you may view purged fits with `fitinfo(..., purged = TRUE`).
#' @export



## * generalize this to also use for maps database (but no sidecars)




fitpurge <- function(rows = NULL, failed = FALSE, undo = NULL) {
   
   
   # -------- helper functions --------
   
   running <- function(x) {                                                               # --- TRUE for fitids that are still running
      z <- info(list(callerid = x), cols = c('callerid', 'status'), 
                table = FALSE, summary = FALSE)
      x %in% z$callerid[z$status %in% c('pending', 'queued', 'running')]
   }
   
   
   
   move_sidecars <- function(ids, from, to, keep = FALSE) {                               # --- move sidecar files
      
      files <- list.files(from)
      
      x <- unlist(c(sapply(ids, function(x) grep(paste0('fit_', x, '_extra.RDS'), files)),
                    sapply(ids, function(x) grep(paste0('fit_', x, '.log'), files)),
                    sapply(ids, function(x) grep(paste0('zz_', x, '_fit.RDS'), files))))
      
      if(keep) {                                                                          # if keep, we're keeping all x files and moving the rest of them
         y <- c(grep('fit_\\d*_extra.RDS', files),
                grep('fit_\\d*.log', files),
                grep('zz_\\d*_fit.RDS', files))
         x <- setdiff(y, x)
      }
      
      if(length(x) == 0)
         return()
      
      message('Moving ', length(x), ifelse(keep, ' stray', ''), ' sidecar files...')
      
      file.copy(file.path(from, files[x]), file.path(to, files[x]), 
                overwrite = TRUE, copy.date = TRUE)
      unlink(file.path(from, files[x]))
   }
   
   # ----------------------------------
   
   
   
   if(sum(!is.null(rows), failed, !is.null(undo)) > 1)
      stop('You may not supply more than one of rows, failed, or undo')
   
   
   pf <- file.path(the$dbdir, 'purged', 'fdb_purged.RDS')                                 # purged database
   md <- the$modelsdir                                                                    # models dir
   pd <- file.path(md, 'purged')                                                          # purged models dir
   
   if(!dir.exists(md))
      dir.create(md, recursive = TRUE)
   
   if(!dir.exists(pd))
      dir.create(pd, recursive = TRUE)
   
   
   load_database('fdb')                                                                   # Get fits database
   
   
   if(!is.null(undo)) {                                                                   # ----- undo -----
      
      if(!file.exists(pf)) {
         message('There are no purged fits')
         return(invisible())
      }
      
      purged <- readRDS(pf)                                                               # get purged database
      if(nrow(purged) == 0){
         message('There are no purged fits')
         return(invisible())
      }
      
      if(undo == 'last')                                                                  # get binary vector of selected fits to unpurge
         these <- purged$purgegroup == max(purged$purgegroup)                             #    either last purgegroup
      else
         these <- purged$id %in% undo                                                     #    or supplied list of ids
      
      the$fdb <- rbind(the$fdb, purged[these, setdiff(names(purged), 'purgegroup')])      # restore fits
      the$fdb <- the$fdb[!duplicated(the$fdb$id), ]                                       # for robustness, make sure fits haven't gotten duplicated
      
      move_sidecars(purged$id[these], pd, md)                                             # restore sidecar files
      
      purged <- purged[!these,]                                                           # drop from purged
      
      saveRDS(purged, pf)                                                                 # save the purged database
      save_database('fdb')                                                                # finally save the fits database once we're all done
      
      message('Restored ', sum(these), ' fits')
   }
   else
   {
      if(dim(the$fdb)[1] == 0) {                                                          # make sure there's something to purge
         move_sidecars(the$fdb$id, md, pd, keep = TRUE)                                   # clean up stray sidecar files
         message('No fits in database')
         return(invisible())
      }
      
      if(failed) {                                                                        # ----- failed: purge failed jobs -----
         rows <- seq_along(the$fdb$id)[!the$fdb$status %in% 'finished']
         rows <- rows[!running(the$fdb$id[rows])]                                         # exclude running jobs ... now purge rows will handle these
         rows <- the$fdb$id[rows]
         if(length(rows) == 0) {
            move_sidecars(the$fdb$id, md, pd, keep = TRUE)                                # clean up stray sidecar files
            stop('No failed jobs to purge')
            return(invisible())
         }
      }
      
      if(is.null(rows)) {                                                                 # if rows is NULL, 
         move_sidecars(the$fdb$id, md, pd, keep = TRUE)                                   # just clean up stray sidecar files
         return(invisible())
      }
      else
         if(identical(rows, 'all'))
            stop('fitpurge(rows = \'all\' is not allowed')
      
      
      rows <- filter_db(rows, 'fdb')                                                      # fits to purge, filtered
      
      r <- running(the$fdb$id[rows])
      if(any(r))
         message('Can\'t purge running fits ', paste(the$fdb$id[rows[r]], collapse = ', '))
      rows <- rows[!r]
      
      if(length(rows) == 0) {
         move_sidecars(the$fdb$id, md, pd, keep = TRUE)                                   # clean up stray sidecar files
         message('No fits to purge')
         return(invisible())
      }
      
      
      
      if(file.exists(pf)) {                                                               # get max purged group
         purged <- readRDS(pf)
         max_pg <- max(purged$purgegroup, 0)
      }
      else
         max_pg <- 0
      
      
      purge <- the$fdb[rows, ]                                                            # pull out purged rows
      the$fdb <- the$fdb[!seq_along(the$fdb$id) %in% rows, ]
      
      purge$purgegroup <- max_pg + 1
      
      if(file.exists(pf))                                                                 # add purged rows to purged database
         purged <- rbind(purged, purge)
      else
         purged <- purge
      
      purged <- purged[!duplicated(purged$id), ]                                          # for robustness, make sure fits haven't gotten duplicated in purged
      
      
      if(!dir.exists(dirname(pf))) 
         dir.create(dirname(pf))
      
      
      saveRDS(purged, pf)                                                                 # save the purged database
      save_database('fdb')                                                                # finally save the fits database once we're all done
      
      
      move_sidecars(purged$id, md, pd)                                                    # move sidecar files to models/purged/
      
      move_sidecars(the$fdb$id, md, pd, keep = TRUE)                                      # clean up stray sidecar files
      
      message(nrow(purge), ' fit', ifelse(nrow(purge) == 1, '', 's'), ' purged')
   }
}
