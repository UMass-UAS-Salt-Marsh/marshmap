   #' Check that each source file exists on the result directory and is up to date
   #' 
   #' @param files Vector of files to check
   #' @param gd Source Drive info (optional), named list of 
   #'    - `dir`            Google directory info, from [get_dir]
   #'    - `sourcedrive`    which source drive (`local`, `google`, or `sftp`)
   #'    - `sftp`           `list(url, user)`
   #' @param sourcedir Origin directory of files
   #' @param resultdir Target directory of files - see if origin files are here and up to date
   #' @returns A vector corresponding to files, TRUE for those that are up to date
   #' @importFrom googledrive drive_reveal
   #' @export
   
      
      'check_files' <- function(files, gd, sourcedir, resultdir) {
         
      
   z <- rep(FALSE, length(files))
   
   for(i in 1:length(files))                                                              # for each file,
      if(file.exists(f <- add_x(file.path(resultdir, file.path(basename(files[i])))))) {  #    if the file (with prepended 'x'!) exists in the results directory,
         sdate <- switch(gd$sourcedrive,                                                  #       get last modified date on source drive
                         'local' = file.mtime(f),
                         'google' = drive_reveal(gd$dir[gd$dir$name == files[i], ],
                                                 what = 'modified_time')$modified_time,
                         'sftp' = gd$dir$date[basename(gd$dir$name) == basename(f)]
         )
         rdate <- file.mtime(f)                                                           #   date on result drive
         z[i] <- rdate >= sdate                                                           #   TRUE if it's present and up to date
      }
   z
}