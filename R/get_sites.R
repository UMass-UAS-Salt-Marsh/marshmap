#' Get names of one or more sites
#' 
#' @param site One or more site names, using 3 letter abbreviation. Use `all` to process all sites. 
#' @returns site Vector of one or more standard 3 letter site abbreviations
#' @keywords internal


get_sites <- function(site) {
   
   
   
   sites <- read_pars_table('sites')
   site <- tolower(site)
   if(site == 'all')                                        # if all sites,
      site <- sites$site                                    #    get list of all of them so we can split across reps in batch mode
   if(site == '')
      stop('No sites specified. Use site = \'all\' for all sites.')
   if(any(m <- !site %in% sites$site))
      stop('Non-existent sites: ', site[m])
   
   return(site)
}