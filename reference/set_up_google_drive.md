# Creates a token to set up the Google Drive

This needs to be run just once for each user of `saltmarsh`. It sends
you to a Google authorization page where you'll need to log in to your
Google account, copy a token, and paste it when you're asked to "Enter
authorization code."

## Usage

``` r
set_up_google_drive()
```

## Details

Once this is done, you can verify access with

    googledrive::drive_find(n_max = 5)

If you write code that needs to access the Google Drive, you'll need to
call the following once per R session. `saltmarsh` takes care of
this–it's only necessary for separate code.

    googledrive::drive_auth(token = readRDS('~/.google_auth/google_drive_token.RDS'))
