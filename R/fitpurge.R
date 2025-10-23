#' Purge selected fits from fits database
#' 
#' Cleans up the fits database of unwanted fits, as well as cleaning up sidecar
#' files. Fits are always reversible. 
#' 
#' Purged rows in the fits database are saved to `databases/purged/fdb_purged.RDS`, 
#' and associated files are moved to `databases/purged/`. Any stray fit sidecar 
#' files (fit_0000_extra.RDS, fit_0000.log, and zz_0000_fit.RDS) are always purged.
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


## X don't allow purging running jobs!
## X need to be robust to missing files in models/ in fitinfo and wherever else
## * fitinfo(purged = TRUE) if TRUE, queries the purged database rather than the active one.
## x when purging fits, add purgegroup to data frame, incrementing with each call
## * locking database also locks purged database -- attend to this in fitinfo
## 
## * when I do this for maps: no sidecar files, I almost don't care about undo but probably want to be consistent


fitpurge <- function(rows = NULL, failed = FALSE, undo = NULL) {
   
   
   running <- function(x) {                                                            # TRUE for fitids that are still running
      z <- info(list(callerid = x), cols = c('callerid', 'status'), 
                table = FALSE, summary = FALSE)
      x %in% z$callerid[z$status %in% c('pending', 'queued', 'running')]
   }
   
   
   if(sum(!is.null(rows), failed, !is.null(undo)) != 1)
      stop('You may not supply more than one of rows, failed, or undo')
   
   
   load_database('fdb')                                                                   # Get fits database
   
   
   if(!is.null(undo)) {                                                                   # ----- undo -----
      
      
      # --------------UNDO PURGE here------------------------
      
   }
   else
   {
      if(dim(the$fdb)[1] == 0)                                                            # make sure there's something to purge
         stop('No fits in database')
      
      
      if(failed) {                                                                        # ----- failed: purge failed jobs -----
         rows <- seq_along(the$fdb$id)[!the$fdb$status %in% 'finished']
         rows <- rows[!running(the$fdb$id[rows])]                                         # exclude running jobs ... now purge rows will handle these
         if(length(rows) == 0)
            stop('No failed jobs to purge')
      }
      
      
      if(!is.null(rows))
         if(identical(rows, 'all'))
            stop('fitpurge(rows = \'all\' is not allowed')
      
      rows <- filter_db(rows, 'fdb')                                                      # fits to purge, filtered
      
      r <- running(the$fdb$id[rows])
      if(any(r))
         message('Can\'t purge running fits ', paste(the$fdb$id[rows[r]], collapse = ', '))
      rows <- rows[!r]
      
      if(length(rows) == 0)
         stop('No fits to purge')
      
      
      if(file.exists(pf <- file.path(the$dbdir, 'purged', 'fdb_purged.RDS'))) {           # get max purged group
         purged <- readRDS(pf)
         max_pg <- max(purged$purgegroup)
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
      
      
      md <- the$modelsdir                                                                 # now move sidecar files to models/purged/
      files <- list.files(md) 
      
      if(!dir.exists(pd <- file.path(md, 'purged')))
         dir.create(pd)

      x <- files[unlist(c(sapply(purged$id, function(x) grep(paste0('fit_', x, '_extra.RDS'), files)),
                          sapply(purged$id, function(x) grep(paste0('fit_', x, '.log'), files)),
                          sapply(purged$id, function(x) grep(paste0('zz_', x, '_fit.RDS'), files))))]   
      
      file.copy(file.path(md, x), file.path(pd, x), overwrite = TRUE, copy.date = TRUE)
      unlink(file.path(md, x))
      
      message(nrow(purge), ' fit', ifelse(nrow(purge) == 1, '', 's'), ' purged')
   }
}
