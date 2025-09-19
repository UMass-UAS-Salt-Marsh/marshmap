#' Resolve directory with embedded `<site>`, `<SITE>`, `<site_name>`, or `<share>`
#' 
#' @param dir Directory path
#' @param site Site name. For Google Drive, use `site_name`; on Unity, use
#'    `tolower(site)`, 3 letter code
#' @param share Share site name. For Google Drive, use `share`
#' @returns Directory path including specified site.
#' @export


resolve_dir <- function(dir, site, share = '') {
   
   
   sites <- read_pars_table('sites')
   x <- sites[tolower(sites$site) == tolower(get_sites(site)$site), ]
   
   z <- sub('<site>', x$site, dir, fixed = TRUE)
   z <- sub('<SITE>', toupper(x$site), z, fixed = TRUE)
   z <- sub('<site_name>', x$site_name, z, fixed = TRUE)
   if(x$share == '')                                                    # share defaults to site_name
      x$share <- x$site_name
   z <- sub('<share>', x$share, z, fixed = TRUE)
   
   z
}
