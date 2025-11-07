# Resolve directory with embedded `<site>`, `<SITE>`, `<site_name>`, or `<share>`

Resolve directory with embedded `<site>`, `<SITE>`, `<site_name>`, or
`<share>`

## Usage

``` r
resolve_dir(dir, site, share = "")
```

## Arguments

- dir:

  Directory path

- site:

  Site name. For Google Drive, use `site_name`; on Unity, use
  `tolower(site)`, 3 letter code

- share:

  Share site name. For Google Drive, use `share`

## Value

Directory path including specified site.
