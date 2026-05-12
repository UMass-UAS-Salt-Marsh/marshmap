#' Write a categorical raster to GeoTIFF with color table and VAT
#' 
#' Takes an in-memory categorical SpatRaster and a class lookup table and 
#' writes a final, GIS-ready GeoTIFF: LZW-compressed, tiled, with a
#' GDAL color table (so values display correctly in QGIS/terra without
#' extra setup) and an ESRI Value Attribute Table sidecar (so values
#' display correctly in ArcGIS).
#' 
#' This consolidates the standard `addColorTable` + `makeNiceTif` + `addVat`
#' dance used in `do_map` and `unet_assemble_map`. Note that GDAL color tables
#' are dense over 0-255: ArcGIS will show every unused integer in the legend
#' until you switch the symbology to "Unique Values". A future enhancement
#' may write a `.qml` (QGIS) or `.lyrx` (ArcGIS) sidecar to clean this up.
#'
#' @param r (SpatRaster) categorical raster, integer-valued, with values 
#'   in 0-255 (INT1U range). NA-valued cells are written as NoData.
#' @param destination (character) path to the output GeoTIFF.
#' @param class_lookup (data frame) with columns `value`, `name`, `color`,
#'   one row per class code present in `r`. Typically built with 
#'   `build_class_lookup()`.
#' @param overwrite (logical) if `TRUE`, an existing destination is replaced.
#' @param qml (logical) if `TRUE`, also write a `.qml` sidecar with sparse
#'   symbology for QGIS. Not yet implemented; included as a stub for future
#'   use.
#' @return Invisibly returns `destination`.
#' @importFrom terra writeRaster values
#' @importFrom rasterPrep addColorTable makeNiceTif addVat
#' @export


write_classified_tif <- function(r, destination, class_lookup, 
                                 overwrite = FALSE, qml = FALSE) {
   
   if(!inherits(r, 'SpatRaster'))
      stop('r must be a SpatRaster')
   
   required <- c('value', 'name', 'color')
   missing_cols <- setdiff(required, names(class_lookup))
   if(length(missing_cols) > 0)
      stop('class_lookup is missing required column(s): ', 
           paste(missing_cols, collapse = ', '))
   
   if(file.exists(destination) && !overwrite)
      stop('destination exists: ', destination, '. Set overwrite = TRUE.')
   
   dir.create(dirname(destination), showWarnings = FALSE, recursive = TRUE)
   
   # Preliminary file
   r0 <- file.path(dirname(destination), 
                   paste0('zz_', basename(destination), '_0',
                          (as.numeric(Sys.time()) %% 1) * 1e7))                # random suffix to avoid collisions
   r0_glob <- paste0(r0, '*')                                                  # all sidecars
   
   writeRaster(r, paste0(r0, '.tif'), overwrite = TRUE, datatype = 'INT1U')
   
   # Build the addColorTable input: value, color, category ('[code] name')
   ct_table <- data.frame(
      value = class_lookup$value,
      color = class_lookup$color,
      category = paste0('[', class_lookup$value, '] ', class_lookup$name),
      stringsAsFactors = FALSE
   )
   
   vrt_file <- addColorTable(paste0(r0, '.tif'), table = ct_table)
   
   # Build the VAT: value, plus all lookup columns
   vat <- data.frame(
      value = class_lookup$value,
      class = class_lookup$value,                                              # 'class' col matches existing convention
      name = class_lookup$name,
      color = class_lookup$color,
      stringsAsFactors = FALSE
   )
   
   makeNiceTif(source = vrt_file, destination = destination, overwrite = overwrite,
               overviewResample = 'nearest', stats = FALSE, vat = TRUE)
   addVat(destination, attributes = vat)
   
   # QML sidecar - stub for future implementation
   if(qml) {
      warning('qml = TRUE not yet implemented; ignoring.')
      # Future: write a .qml file alongside `destination` with a 
      # paletted/unique-values renderer that lists only the codes in 
      # class_lookup, eliminating the 0-255 colormap clutter in QGIS.
      # ArcGIS users would need a .lyrx; not planned.
   }
   
   unlink(Sys.glob(r0_glob))                                                   # clean up temp files
   
   invisible(destination)
}
