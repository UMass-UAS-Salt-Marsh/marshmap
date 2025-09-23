#' Check that each source file exists on the result directory and is up to date
#' 
#' @param files Vector of files to check
#' @param gd Source Drive info (optional), named list of 
#'    - `dir`            Google directory info, from [get_dir]
#'    - `sourcedrive`    which source drive (`local`, `google`, or `sftp`)
#'    - `sftp`           `list(url, user)`
#' @param sourcedir Origin directory of files
#' @param resultdir Target directory of files - see if origin files are here and up to date
#' @returns A vector corresponding to files, TRUE for those that exist and are up to date
#' @importFrom googledrive drive_reveal
#' @keywords internal


check_files <- function(files, gd, sourcedir, resultdir) {
   
   
   z <- rep(FALSE, length(files))
   
   for(i in seq_along(files)) {                                                           # for each file,
      f <- file.path(resultdir, file.path(basename(files[i])))                            #    local file path and name
      if(file.exists(f)) {                                                                #    if the file exists in the results directory,
         sdate <- switch(gd$sourcedrive,                                                  #       get last modified date on source drive
                         'local' = file.mtime(f),
                         'google' = drive_reveal(gd$dir[gd$dir$name == files[i], ],
                                                 what = 'modified_time')$modified_time,
                         'sftp' = gd$dir$date[basename(gd$dir$name) == basename(files[i])]
         )
         rdate <- file.mtime(f)                                                           #   date on result drive
         z[i] <- rdate >= sdate                                                           #   TRUE if it's present and up to date
      }
   }
   z
}