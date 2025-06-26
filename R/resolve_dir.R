#' Resolve directory with embedded `<site>` or `<share>`
#' 
#' @param dir Directory path
#' @param site Site name. For Google Drive, use `site_name`; on Unity, use
#'    `tolower(site)`, 3 letter code
#' @param share Share site name. For Google Drive, use `share`
#' @returns Directory path including specified site.
#' @export


resolve_dir <- function(dir, site, share = site) {
   
   
   z <- sub('<site>', site, dir, fixed = TRUE)
   z <- sub('<share>', share, z, fixed = TRUE)
   
   z
}
