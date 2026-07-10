# Write a categorical raster to GeoTIFF with color table and VAT

Takes an in-memory categorical SpatRaster and a class lookup table and
writes a final, GIS-ready GeoTIFF: LZW-compressed, tiled, with a GDAL
color table (so values display correctly in QGIS/terra without extra
setup) and an ESRI Value Attribute Table sidecar (so values display
correctly in ArcGIS).

## Usage

``` r
write_classified_tif(
  r,
  destination,
  class_lookup,
  overwrite = FALSE,
  qml = FALSE
)
```

## Arguments

- r:

  (SpatRaster) categorical raster, integer-valued, with values in 0-255
  (INT1U range). NA-valued cells are written as NoData.

- destination:

  (character) path to the output GeoTIFF.

- class_lookup:

  (data frame) with columns `value`, `name`, `color`, one row per class
  code present in `r`. Typically built with
  [`build_class_lookup()`](https://umass-uas-salt-marsh.github.io/marshmap/reference/build_class_lookup.md).

- overwrite:

  (logical) if `TRUE`, an existing destination is replaced.

- qml:

  (logical) if `TRUE`, also write a `.qml` sidecar with sparse symbology
  for QGIS. Not yet implemented; included as a stub for future use.

## Value

Invisibly returns `destination`.

## Details

This consolidates the standard `addColorTable` + `makeNiceTif` +
`addVat` dance used in `do_map` and `unet_assemble_map`. Note that GDAL
color tables are dense over 0-255: ArcGIS will show every unused integer
in the legend until you switch the symbology to "Unique Values". A
future enhancement may write a `.qml` (QGIS) or `.lyrx` (ArcGIS) sidecar
to clean this up.
