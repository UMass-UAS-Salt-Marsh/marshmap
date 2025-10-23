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
## * when purging fits, add purgegroup to data frame, incrementing with each call
## * locking database also locks purged database -- attend to this in fitinfo
## 
## * when I do this for maps: no sidecar files, I almost don't care about undo but probably want to be consistent


fitpurge <- function(rows = '', failed = FALSE, undo = FALSE) {
   
   
   running <- function(x) {                                                         # TRUE for fitids that are still running
      z <- info(list(callerid = x), cols = c('callerid', 'status'), 
                table = FALSE, summary = FALSE)
      x %in% z$callerid[z$status %in% c('pending', 'queued', 'running')]
   }
   
   
   if(sum(!is.null(rows), failed, !is.null(undo)) != 1)
      stop('You must supply one and only one of rows, failed, or undo')
   
   
   load_database('fdb')                                                                # Get fits database
   
   
   if(!is.null(undo)) {                                                                # ----- undo -----
      
      
      # --------------UNDO PURGE here------------------------
      
   }
   else
   {
      if(dim(the$fdb)[1] == 0)                                                         # make sure there's something to purge
         stop('No fits in database')
      
      
      if(failed) {                                                                     # ----- failed: purge failed jobs -----
         rows <- seq_along(the$fdb$id)[!the$fdb$status %in% 'finished']
         rows <- rows[!running(the$fdb$id[rows])]                                      # exclude running jobs ... now purge rows will handle these
      }
      

      if(!is.null(rows))
         if(rows == 'all')
            stop('fitpurge(rows = \'all\' is not allowed')
      
      rows <- filter_db(rows, 'fdb')                                                   # fits, filtered
      
      
      
      
      # PURGE ROWS
      # pull rows out of fdb.RDS
      # add them to purged/fdb.RDS
      # save both files
      # then move stray files to models/purged/   *** always do this, so fitpurge() purges stray files
      
   }
}
