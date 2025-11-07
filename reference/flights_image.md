# Create cached images of orthophotos for display in `screen`

Create cached images of orthophotos for display in `screen`

## Usage

``` r
flights_image(data, cdir, file, rgb, extent, footprint, pixels = 1200)
```

## Arguments

- data:

  raster of ortho image

- cdir:

  cache directory

- file:

  File name to write cache to

- rgb:

  RGB bands, in order (reversed for Mica)

- extent:

  Extent of image; one of `full`, `inset1`, or `inset2`

- footprint:

  footprint shapefile object

- pixels:

  Maximum resolution in pixels
