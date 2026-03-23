#' Assemble U-Net map predictions into a georeferenced GeoTIFF
#'
#' Reads per-patch class probabilities, averages overlapping predictions,
#' takes argmax, maps back to original class numbers, and writes a GeoTIFF
#' with a color table matching the project classes.
#'
#' @param patches_dir Directory with map patches, probabilities, origins, and metadata
#' @param output_file Full path for the output GeoTIFF
#' @param config Config list (from prep yaml, with `classes` and `site`)
#' @param write_probs If TRUE, also write per-class probability layers as a
#'   multi-band GeoTIFF alongside the classification
#' @importFrom terra rast ext crs values writeRaster
#' @importFrom reticulate import
#' @importFrom rasterPrep addColorTable makeNiceTif addVat
#' @keywords internal


unet_assemble_map <- function(patches_dir, output_file, config, 
                              write_probs = FALSE) {
   
   
   np <- import('numpy')
   
   site <- toupper(config$site)
   
   # ----- Load metadata -----
   meta <- jsonlite::fromJSON(file.path(patches_dir, 'map_metadata.json'))
   origins <- read.csv(file.path(patches_dir, 'patch_origins.csv'))
   
   n_patches  <- meta$n_patches
   patch_size <- meta$patch_size
   n_rows     <- meta$n_rows_rast
   n_cols     <- meta$n_cols_rast
   rez        <- meta$resolution
   
   
   # ----- Load probabilities and nodata mask -----
   message('Loading probabilities...')
   probs <- np$load(file.path(patches_dir, paste0(site, '_map_probs.npy')))    # (n_patches, n_classes, H, W)
   nodata <- np$load(file.path(patches_dir, paste0(site, '_map_nodata.npy')))  # (n_patches, H, W)
   
   n_classes <- dim(probs)[2]
   original_classes <- config$classes
   
   message(sprintf('Assembling %d patches into %d x %d raster (%d classes)...',
                   n_patches, n_cols, n_rows, n_classes))
   
   
   # ----- Allocate accumulator matrices -----
   # Using plain matrices to avoid terra overhead during accumulation
   prob_accum <- array(0, dim = c(n_rows, n_cols, n_classes))                  # summed probabilities
   count <- matrix(0L, nrow = n_rows, ncol = n_cols)                           # number of contributing patches
   nodata_accum <- matrix(0L, nrow = n_rows, ncol = n_cols)                    # nodata pixel count
   
   
   # ----- Accumulate -----
   message('Accumulating predictions...')
   for(i in seq_len(n_patches)) {
      r0 <- origins$row[i] + 1                                                # 1-indexed
      c0 <- origins$col[i] + 1
      r1 <- min(r0 + patch_size - 1, n_rows)
      c1 <- min(c0 + patch_size - 1, n_cols)
      
      actual_h <- r1 - r0 + 1
      actual_w <- c1 - c0 + 1
      
      nd_patch <- nodata[i, 1:actual_h, 1:actual_w]                           # nodata mask for this patch
      
      for(k in seq_len(n_classes))
         prob_accum[r0:r1, c0:c1, k] <- prob_accum[r0:r1, c0:c1, k] + 
            probs[i, k, 1:actual_h, 1:actual_w] * nd_patch                    # only accumulate valid pixels
      
      count[r0:r1, c0:c1] <- count[r0:r1, c0:c1] + nd_patch
      nodata_accum[r0:r1, c0:c1] <- nodata_accum[r0:r1, c0:c1] + 
         as.integer(nd_patch == 0)
      
      if(i %% 500 == 0)
         message(sprintf('  Processed %d / %d patches', i, n_patches))
   }
   
   rm(probs, nodata)                                                           # free memory
   
   
   # ----- Average probabilities -----
   message('Averaging overlapping predictions...')
   is_nodata <- count == 0
   count[is_nodata] <- 1                                                       # avoid division by zero
   
   for(k in seq_len(n_classes))
      prob_accum[, , k] <- prob_accum[, , k] / count
   
   
   # ----- Argmax to get predicted class -----
   message('Computing class predictions...')
   pred_internal <- apply(prob_accum, c(1, 2), which.max) - 1L                 # 0-indexed internal class
   
   # Map to original class numbers
   pred_original <- matrix(original_classes[pred_internal + 1], 
                           nrow = n_rows, ncol = n_cols)
   pred_original[is_nodata] <- NA                                              # set nodata pixels to NA
   
   
   # ----- Create georeferenced raster -----
   message('Writing GeoTIFF...')
   template <- rast(nrows = n_rows, ncols = n_cols,
                    xmin = meta$rast_xmin, xmax = meta$rast_xmax,
                    ymin = meta$rast_ymin, ymax = meta$rast_ymax,
                    crs = meta$crs)
   
   result_rast <- setValues(template, as.vector(t(pred_original)))             # terra expects column-major, t() to match
   
   
   # ----- Preliminary save -----
   dir.create(dirname(output_file), showWarnings = FALSE, recursive = TRUE)
   f0 <- paste0(output_file, '.tmp.tif')
   writeRaster(result_rast, f0, overwrite = TRUE, datatype = 'INT1U')
   
   
   # ----- Color table and VAT -----
   classes <- read_pars_table('classes')
   
   # Build VAT from our predicted classes
   pred_classes <- sort(unique(as.vector(pred_original[!is.na(pred_original)])))
   vat <- data.frame(
      value = pred_classes,
      subclass = as.integer(pred_classes)
   )
   vat <- merge(vat, classes[, c('subclass', 'subclass_name', 'subclass_color')],
                by = 'subclass', sort = TRUE)
   vat <- vat[, c('value', 'subclass', 'subclass_name', 'subclass_color')]
   names(vat) <- c('value', 'subclass', 'name', 'color')
   
   vat2 <- data.frame(
      value = vat$value,
      color = vat$color,
      category = paste0('[', vat$subclass, '] ', vat$name)
   )
   
   vrt_file <- addColorTable(f0, table = vat2)
   makeNiceTif(source = vrt_file, destination = output_file, overwrite = TRUE,
               overviewResample = 'nearest', stats = FALSE, vat = TRUE)
   addVat(output_file, attributes = vat)
   
   unlink(f0)                                                                  # delete temp file
   unlink(paste0(f0, '*'))                                                     # and any sidecars
   
   
   # ----- Optional probability layers -----
   if(write_probs) {
      message('Writing probability layers...')
      prob_file <- sub('\\.tif$', '_probs.tif', output_file)
      prob_stack <- rast(replicate(n_classes, template))
      names(prob_stack) <- paste0('prob_', original_classes)
      
      for(k in seq_len(n_classes)) {
         prob_layer <- prob_accum[, , k]
         prob_layer[is_nodata] <- NA
         values(prob_stack[[k]]) <- as.vector(t(prob_layer))
      }
      
      writeRaster(prob_stack, prob_file, overwrite = TRUE, datatype = 'FLT4S')
      message('Probability layers saved to: ', prob_file)
   }
   
   
   mpix <- sum(!is_nodata) / 1e6
   message(sprintf('Map assembled: %s (%.1f M valid pixels)', output_file, mpix))
   
   invisible(list(output_file = output_file, mpix = mpix))
}
