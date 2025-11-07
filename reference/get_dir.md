# Return directory listing as a data frame from the local drive, Google Drive, or SFTP site

A sister function to get_file

## Usage

``` r
get_dir(path, sourcedrive = "local", sftp)
```

## Arguments

- path:

  directory path (must end with '/' on Google Drive)

- sourcedrive:

  one of `local`, `google`, or `sftp`

- sftp:

  list of url = address of site, user = credentials (optional)

## Details

Returns data frame with name (filenames), and id (Google Drive id, only
if `sourcedrive = `google\`)

- when `sourcedrive = local` name is full path to local files

- when `sourcedrive = google`, name is just the base name

- when `sourcedrive = sftp`, name is the full path to files on the SFTP
  site

- When directories aren't found, throw an error

Notes:

- paths for Google Drive are case-sensitive

- initial runs with Google Drive in a session open the browser for
  authentication or wait for input from the console, so don't run
  blindly when using the Google Drive

- SFTP directory info is crazy. Apparently the format is highly
  platform-dependent. The targeted use for this is running on Unity /
  fetching files from SFTP on the NAS that we don't have yet, so I'll
  have to revisit this to tailor it to the specific platforms.

- When testing this on my laptop / fetching files via SFTP from the
  Landscape Ecology cluster, I found two date issues:

  1.  Seconds are truncated. I'm adding one minute so date checks won't
      fail. It seems safe to assume source files won't be updated within
      a minute of downloading them.

  2.  Strangely, summer dates are reported differently by xplorer2 and
      DOS/Command Prompt (1:12 pm) vs. Win Explorer, FileZilla, and this
      code (2:12 pm). Absolutely crazy. In the final setup, we'll have
      Linux servers on both sides so hopefully this'll clear up.
