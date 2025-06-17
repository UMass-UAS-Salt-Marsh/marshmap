#' Resolve directory with embedded `<site>` 
#' 
#' @param dir Directory path
#' @param site Site name. For Google Drive, use `site_name`; on Unity, use
#'    `tolower(site)`, 3 letter code
#' @returns Directory path including specified site.
#' @export


resolve_dir <- function(dir, site) 
   
   
   sub('<site>', site, dir, fixed = TRUE)
