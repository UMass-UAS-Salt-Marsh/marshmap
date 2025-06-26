#' Resolve directory with embedded `<site>` or `<share>`
#' 
#' @param dir Directory path
#' @param site Site name. For Google Drive, use `site_name`; on Unity, use
#'    `tolower(site)`, 3 letter code
#' @param share Share site name. For Google Drive, use `share`
#' @returns Directory path including specified site.
#' @export


resolve_dir <- function(dir, site, share = site) {
   
   
   sub('<site>', site, dir, fixed = TRUE)
   sub('<share>', share, dir, fixed = TRUE)
}
