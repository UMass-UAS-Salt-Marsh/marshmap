#' Purge selected fits from fits database
#' 
#' Cleans up the fits database of unwanted fits, as well as cleaning up sidecar
#' files. Purges are always reversible. 
#' 
#' Purged rows in the fits database are saved to `databases/purged/fdb_purged.RDS`, 
#' and associated files are moved to `models/purged/`. Any stray fit sidecar 
#' files (`fit_0000_extra.RDS`, `fit_0000.log`, and `zz_0000_fit.RDS`) are also purged.
#' 
#' You can undo previous purges or unpurge specific fits with `undo`. Use 
#' `fitinfo(..., purged = TRUE)` to view purged fits.
#' 
#' If you're hurting for disk space, it's fair game to delete 
#' `databases/purged/fdb_purged.RDS` and files in `models/purged/`. Doing so
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
#'    matter whether you've run more fits since a purge. You may supply either:
#'  - `undo = 'last'`, reverses the previous purge call, and the 
#'    database and associated files are restored. Call `fitpurge(undo = 'last')` 
#'    repeatedly to roll back farther. 
#'  - a vector of fit ids corresponding to previously purged fits.
#'    Note that you may view purged fits with `fitinfo(..., purged = TRUE`).
#' @export


fitpurge <- function(rows = NULL, failed = FALSE, undo = NULL) {
   
   
   db_purge(which = 'fit', db_name = 'fdb', id_name = 'id', rows = rows, failed = failed, undo = undo)
}