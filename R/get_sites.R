#' Get names of one or more sites
#' 
#' @param site One or more site names, using 3 letter abbreviation. Use `all` to process all sites. 
#' @returns site Data frame with one or more rows of:
#' \item{site}{Standard 3 letter site abbreviation}
#' \item{site_name}{Site name}
#' @keywords internal


get_sites <- function(site) {
   
   
   sites <- read_pars_table('sites')
   site <- tolower(site)
   if(length(site) == 0 || site[1] == '')
      stop('No sites specified. Use site = \'all\' for all sites.')
   if(site[1] == 'all')                                              # if all sites,
      site <- sites$site                                             #    get list of all of them so we can split across reps in batch mode
   if(any(m <- !site %in% sites$site))
      stop('Non-existent sites: ', site[m])
   
   return(sites[match(site, sites$site), c('site', 'site_name')])
}