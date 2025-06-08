#' Return directory listing as a data frame from the local drive, Google Drive, or SFTP site
#'
#' A sister function to get_file
#' 
#' Returns data frame with name (filenames), and id (Google Drive id, only if `sourcedrive = `google`)
#' - when `sourcedrive = local` name is full path to local files
#' - when `sourcedrive = google`, name is just the base name
#' - when `sourcedrive = sftp`, name is the full path to files on the SFTP site
#' - When directories aren't found, the name is added to the log and NULL is returned
#'        
#' Notes: 
#' - paths for Google Drive are case-sensitive
#' - initial runs with Google Drive in a session open the browser for authentication or wait
#'   for input from the console, so don't run blindly when using the Google Drive
#' - SFTP directory info is crazy. Apparently the format is highly platform-dependent. The targeted
#'   use for this is running on Unity / fetching files from SFTP on the NAS that we don't have yet,
#'   so I'll have to revisit this to tailor it to the specific platforms.
#' - When testing this on my laptop / fetching files via SFTP from the Landscape Ecology cluster, I found two date issues:
#'   1. Seconds are truncated. I'm adding one minute so date checks won't fail. It seems safe to assume source
#'      files won't be updated within a minute of downloading them.
#'   2. Strangely, summer dates are reported differently by xplorer2 and DOS/Command Prompt (1:12 pm) vs. Win 
#'      Explorer, FileZilla, and this code (2:12 pm). Absolutely crazy. In the final setup, we'll have Linux
#'      servers on both sides so hopefully this'll clear up.
#'      
#' @param path directory path (must end with '/' on Google Drive)
#' @param sourcedrive one of `local`, `google`, or `sftp`
#' @param logfile log file, for reporting missing directories (which don't throw an error)
#' @param sftp list of url = address of site, user = credentials (optional)
#' @importFrom RCurl getURL 
#' @importFrom lubridate as_datetime mdy_hm
#' @export


get_dir <- function(path, sourcedrive = 'local', logfile, sftp) {
   
   
   path <- gsub('/+', '/', paste0(path, '/'))         # clean up for Google Drive (dir must end in a slash; no doubled slashes)
   
   z <- switch(sourcedrive,                                                               # case sourcedrive,  
               'local' = {
                  t <- list.files(path)
                  if(length(t) == 1 && t == '')
                     NULL
                  else
                     data.frame(name = paste0(path, '/', t))                              #    local directory
               },         
               'google' = drive_walk_path(path),                                          #    Google Drive directory
               'sftp' = {
                  url <- gsub('/+', '/', paste0(file.path(sftp$url, path), '/'))          #    SFTP directory with file dates 
                  url <- gsub(' ', '%20', url)                                            #    and replace goddamn spaces with %20
                  d <- tryCatch(getURL(url, userpwd = sftp$user),
                                error = function(cond)
                                   NULL)
                  if(!is.null(d)) {
                     d <- strsplit(d, '\n')[[1]]
                     'grab_date' <- function(x) mdy_hm(substr(sub('\\s*\\d*\\s*', '', x), 1, 18))           #    pull the date out of the directory listing
                     'grab_name' <- function(x) paste0(path, substring(sub('\\s*\\d*\\s*', '', x), 20))     #    path and filename
                     data.frame(name = unlist(lapply(d, FUN = grab_name)), date = as_datetime(unlist(lapply(d, FUN = grab_date)) + 60))  #    add one minute to truncated dates
                  }
               })
   
   if(is.null(z)) {
      msg(paste0('*** Missing directory: ', path), logfile)
      z <- NULL
   }
   
   z
}
