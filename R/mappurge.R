#' Purge selected maps from maps database
#' 
#' Cleans up the maps database of unwanted maps, ***as well as cleaning up sidecar
#' files***. Purges are always reversible. 
#' 
#' Purged rows in the maps database are saved to `databases/purged/mdb_purged.RDS`, 
#' and associated files are moved to `databases/purged/`.
#' 
#' You can undo previous purges or unpurge specific maps with `undo`. Use 
#' `mapinfo(..., purged = TRUE)` to view purged maps.
#' 
#' If you're hurting for disk space, it's fair game to delete 
#' `databases/purged/mdb_purged.RDS` and files in `databases/purged/`. Doing so
#' will prevent you from recovering purged maps, of course.
#' 
#' 
#' ***Do I want purging maps to delete TIFFs?!***
#' 
#' @param rows Selected rows in the maps database. Use one of
#'  - an empty string doesn't purge any maps, but does purge stray map files
#'  - a vector of `mapids` to purge those maps
#'  - a named list to filter maps. List items are `<field in mdb> = <value>`, 
#'    where `<value>` is a regex for character fields, or an actual value (or vector of 
#'    values) for logical or numeric fields.
#' @param failed If TRUE, all maps where `success` is `FALSE` or `NA` are purged.
#'    This is an alternative to specifying `rows`.
#' @param undo Undo previous purges. There is no time limit on undoing, and it doesn't
#'    matter whether you've run more maps since a purge. You may supply either:
#'  - `undo = 'last'`, reverses the previous purge call, and the 
#'    database and associated files are restored. Call `mappurge(undo = 'last')` 
#'    repeatedly to roll back farther. 
#'  - a vector of map ids corresponding to previously purged maps.
#'    Note that you may view purged maps with `mapinfo(..., purged = TRUE`).
#' @export


mappurge <- function(rows = NULL, failed = FALSE, undo = NULL) {
   
   
   db_purge(which = 'map', db_name = 'mdb', id_name = 'mapid', rows = rows, failed = failed, undo = undo)
}