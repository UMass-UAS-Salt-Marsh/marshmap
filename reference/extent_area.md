# Give the area of a clip vector

Give the area of a clip vector

## Usage

``` r
extent_area(clip, units = "ha", crs)
```

## Arguments

- clip:

  Vector of `xmin`, `xmax`, `ymin`, `ymax`

- units:

  Area units to return

- crs:

  Coordinate reference system of clip. Pass the CRS from the relevant
  raster (e.g., `crs(my_raster)`) to ensure correctness regardless of
  the project's coordinate system.
