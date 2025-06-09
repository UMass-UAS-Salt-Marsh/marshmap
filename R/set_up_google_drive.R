#' Creates a token to set up the Google Drive
#' 
#' This needs to be run just once for each user of `saltmarsh`. It sends you
#' to a Google authorization page where you'll need to log in to your Google
#' account, copy a token, and paste it when you're asked to "Enter authorization code."
#' 
#' Once this is done, you can verify access with 
#' 
#' ```
#' googledrive::drive_find(n_max = 5)
#' ```
#' 
#' If you write code that needs to access the Google Drive, you'll need to call the
#' following once pre R session. `saltmarsh` takes care of this--it's only necessary
#' for separate code.
#' 
#' ```
#' googledrive::drive_auth(token = readRDS('~/.google_auth/google_drive_token.RDS'))
#' ```
#' 
#' @importFrom gargle token_fetch
#' @importFrom googledrive drive_auth drive_find
#' @export


set_up_google_drive <- function() {
   
   
   token <- token_fetch(scopes = 'https://www.googleapis.com/auth/drive')    # have to do the authorization dance here
   file <- '~/.google_auth/google_drive_token.RDS'
   saveRDS(token, file)
   drive_auth(token = readRDS(file))
   
   message('Google Drive authorization token has been created. You can verify access by running\n   googledrive::drive_find(n_max = 5)')
}
