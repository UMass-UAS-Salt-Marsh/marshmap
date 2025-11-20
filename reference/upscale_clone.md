# Clones a site directory at a new grain

- this is experimental, to see if true rescaling helps

- you'll have to add site to sites.txt on your own **before** running
  this

- there is currently no path to use `gather` on the cloned site; I'll
  add it if this seems promising

- upscaled orthos are not cloned

- rejected orthos are not cloned

- scores and comments are copied to the new site

- this doesn't bother with blocks files

- this only affects the `flights` directory. You should be able to run
  `screen`, `derive`, `sample`, and other functions normally after
  cloning.

- I could add `sd` as an option, making multiple results. You can also
  specify arbitrary functions, so this would be a good place for other
  upscaling funs.

## Usage

``` r
upscale_clone(site, newsite, cellsize)
```

## Arguments

- site:

  Site name

- newsite:

  Name for cloned site

- cellsize:

  Cell size for new site (m)
