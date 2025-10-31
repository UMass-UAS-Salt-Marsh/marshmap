#' Purge selected fits or maps from database
#' 
#' Called by `fitpurge` or `mappurge` to purge database rows or restore them, as well
#' as purging or restoring sidecar files.
#' 
#' @param which Which database? Either `fit` or `map`
#' @param db_name Either 'fdb' or 'mdb'
#' @param id_name Either `fitid` or `mapid`
#' @param rows Selected rows in the database. Use one of
#'  - an empty string doesn't purge any rows, but does purge stray fit sidecar files
#'  - a vector of ids to purge those rows
#'  - a named list to filter rows. List items are `<field in database> = <value>`, 
#'    where `<value>` is a regex for character fields, or an actual value (or vector of 
#'    values) for logical or numeric fields.
#' @param failed If TRUE, all rows where `success` is `FALSE` or `NA` are purged.
#'    This is an alternative to specifying `rows`.
#' @param undo Undo previous purges. There is no time limit on undoing, and it doesn't
#'    matter whether you've run more fits or maps since a purge. You may supply either:
#'  - `undo = 'last'`, reverses the previous purge call, and the 
#'    database and associated files are restored.
#'  - a vector of fit ids corresponding to previously purged rows.
#'    Note that you may view purged fits with `fitinfo` or `mapinfo` with `purged = TRUE`.
#' @importFrom slurmcollie info
#' @keywords internal



## * generalize this to also use for maps database (but no sidecars)




db_purge <- function(which, db_name, id_name, rows, failed, undo) {
   
   
   # -------- helper functions --------
   
   running <- function(x) {                                                               # --- TRUE for ids that are still running
      z <- info(list(callerid = x), cols = c('callerid', 'status'), 
                table = FALSE, summary = FALSE)
      x %in% z$callerid[z$status %in% c('pending', 'queued', 'running')]
   }
   
   
   
   move_sidecars <- function(ids, from, to, keep = FALSE) {                               # --- move sidecar files
      
      if(which == 'fit') {                                                                #    only do stuff for fits
         files <- list.files(from)
         
         x <- unlist(c(sapply(ids, function(x) grep(paste0('fit_', x, '_extra.RDS'), files)),
                       sapply(ids, function(x) grep(paste0('fit_', x, '.log'), files)),
                       sapply(ids, function(x) grep(paste0('zz_', x, '_fit.RDS'), files))))
         
         if(keep) {                                                                          #    if keep, we're keeping all x files and moving the rest of them
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
   }
   
   # ----------------------------------
   
   
   if(sum(!is.null(rows), failed, !is.null(undo)) > 1)
      stop('You may not supply more than one of rows, failed, or undo')
   
   
   pf <- file.path(the$dbdir, 'purged', paste0(db_name, '_purged.RDS'))                   # purged database
   md <- the$modelsdir                                                                    # models dir
   pd <- file.path(md, 'purged')                                                          # purged models dir
   
   if(!dir.exists(md))
      dir.create(md, recursive = TRUE)
   
   if(!dir.exists(pd))
      dir.create(pd, recursive = TRUE)
   
   
   load_database(db_name)                                                                 # Get database
   db <- the[[db_name]]
   
   
   if(!is.null(undo)) {                                                                   # ----- undo -----
      
      if(!file.exists(pf)) {
         message('There are no purged ', which, 's')
         return(invisible())
      }
      
      purged <- readRDS(pf)                                                               # get purged database
      if(nrow(purged) == 0){
         message('There are no purged ', which, 's')
         return(invisible())
      }
      
      if(undo == 'last')                                                                  # get binary vector of selected rows to unpurge
         these <- purged$purgegroup == max(purged$purgegroup)                             #    either last purgegroup
      else
         these <- purged[[id_name]] %in% undo                                             #    or supplied list of ids
      
      restored <- purged[[id_name]][these]
      
      db <- rbind(db, purged[these, setdiff(names(purged), 'purgegroup')])                # restore rows
      db <- db[!duplicated(db[[id_name]]), ]                                              # for robustness, make sure rows haven't gotten duplicated
      
      move_sidecars(purged[[id_name]][these], pd, md)                                     # restore sidecar files
      
      purged <- purged[!these,]                                                           # drop from purged
      
      saveRDS(purged, pf)                                                                 # save the purged database
      
      the[[db_name]] <- db
      save_database(db_name)                                                              # finally save the database once we're all done
      
      message('Restored ', sum(these), ' ', which, 's')
      message('  Restored ', which, 'ids: ', paste(restored, collapse = ', '))
   }
   else
   {
      if(dim(db)[1] == 0) {                                                               # make sure there's something to purge
         move_sidecars(db[[id_name]], md, pd, keep = TRUE)                                # clean up stray sidecar files
         message('No ', which, 's in database')
         return(invisible())
      }
      
      
      if(failed) {                                                                        # ----- failed: purge failed jobs -----
         rows <- seq_along(db[[id_name]])[!db$status %in% 'finished']
         rows <- rows[!running(db[[id_name]][rows])]                                      # exclude running jobs ... now purge rows will handle these
         rows <- db[[id_name]][rows]
         if(length(rows) == 0) {
            move_sidecars(db[[id_name]], md, pd, keep = TRUE)                             # clean up stray sidecar files
            stop('No failed jobs to purge')
            return(invisible())
         }
      }
      
      
      if(is.null(rows)) {                                                                 # if rows is NULL, 
         move_sidecars(db[[id_name]], md, pd, keep = TRUE)                                # just clean up stray sidecar files
         return(invisible())
      }
      else
         if(identical(rows, 'all'))
            stop(which, 'purge(rows = \'all\' is not allowed')

      
      rows <- filter_db(rows, db_name)                                                    # ----- rows to purge, filtered -----
      
      r <- running(db[[id_name]][rows])
      if(any(r))
         message('Can\'t purge running ', which, 's', paste(db[[id_name]][rows[r]], collapse = ', '))
      if(length(r) != 0)
         rows <- rows[!r]
      
      if(length(rows) == 0) {
         move_sidecars(db[[id_name]], md, pd, keep = TRUE)                                # clean up stray sidecar files
         message('No ', which, 's to purge')
         return(invisible())
      }
      
      
      
      if(file.exists(pf)) {                                                               # get max purged group
         purged <- readRDS(pf)
         max_pg <- max(purged$purgegroup, 0)
      }
      else
         max_pg <- 0
      
      
      purge <- db[rows, ]                                                                 # pull out purged rows
      db <- db[!seq_along(db[[id_name]]) %in% rows, ]
      
      purge$purgegroup <- max_pg + 1
      
      if(file.exists(pf))                                                                 # add purged rows to purged database
         purged <- rbind(purged, purge)
      else
         purged <- purge
      
      purged <- purged[!duplicated(purged[[id_name]]), ]                                  # for robustness, make sure rows haven't gotten duplicated in purged
      
      
      if(!dir.exists(dirname(pf))) 
         dir.create(dirname(pf))
      
      saveRDS(purged, pf)                                                                 # save the purged database
      
      the[[db_name]] <- db
      save_database(db_name)                                                              # finally save the database once we're all done
      
      
      move_sidecars(purged[[id_name]], md, pd)                                            # move sidecar files to models/purged/
      
      move_sidecars(db[[id_name]], md, pd, keep = TRUE)                                   # clean up stray sidecar files
      
      message(nrow(purge), ' ', which, ifelse(nrow(purge) == 1, '', 's'), ' purged')
      message('  Purged ', which, 'ids: ', paste(purge[[id_name]], collapse = ', '))
   }
}
