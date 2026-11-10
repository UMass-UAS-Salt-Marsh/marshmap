#' Check that each source file exists on the result directory and is up to date
#' 
#' @param files Vector of source files to check (paths as listed by [get_dir])
#' @param gd Source Drive info (optional), named list of 
#'    - `dir`            Google directory info, from [get_dir]
#'    - `sourcedrive`    which source drive (`local`, `google`, or `sftp`)
#'    - `sftp`           `list(url, user)`
#' @param sourcedir Origin directory of files (unused; files carry their paths)
#' @param resultdir Target directory of files - see if origin files are here and up to date
#' @returns A vector corresponding to files, TRUE for those that exist and are up to date
#' @keywords internal


check_files <- function(files, gd, sourcedir, resultdir) {
   

   z <- rep(FALSE, length(files))
   
   for(i in seq_along(files)) {                                                           # for each file,
      f <- file.path(resultdir, basename(files[i]))                                       #    local file path and name
      if(file.exists(f))                                                                  #    if the file exists in the results directory,
         z[i] <- file.mtime(f) >= source_mtime(files[i], gd)                              #       TRUE if it's present and up to date
   }
   z
}



#' Last modified date of a file on the source drive
#' 
#' @param file Source file path. For `local`, this is the full path; for Google Drive and SFTP,
#'    the file is looked up by name (case-insensitive) in `gd$dir`.
#' @param gd Source drive info; see [check_files]
#' @returns Last modified date (POSIXct)
#' @importFrom googledrive drive_reveal
#' @keywords internal


source_mtime <- function(file, gd) {
   
   
   hit <- function()                                                                      # rows of directory listing matching file
      gd$dir[tolower(basename(gd$dir$name)) == tolower(basename(file)), ]
   
   sdate <- switch(gd$sourcedrive,
                   'local' = if(file.exists(file)) file.mtime(file),
                   'google' = drive_reveal(hit(), what = 'modified_time')$modified_time,
                   'sftp' = hit()$date
   )
   if(length(sdate) == 0)
      stop('File ', file, ' doesn\'t exist on source drive')
   sdate
}
