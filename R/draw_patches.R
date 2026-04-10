#' Draw training patches for visual QC
#'
#' Reads numpy patch files and writes RGB TIFFs with class labels
#' overlaid in color. Used to verify that the entire pipeline from shapefile 
#' through patch extraction through numpy export produces correct, aligned data.
#'
#' @param data_dir Directory containing numpy files (e.g., .../set1)
#' @param site Site name (e.g., 'NOR')
#' @param dataset Which dataset to draw from: 'train', 'validate', or 'test'
#' @param n Number of patches to draw (default 5). Ignored if patchno is specified.
#' @param patchno Optional integer vector of specific patch indices to draw
#' @param rgb_channels Which channels to use for RGB display (default c(3, 2, 1) 
#'   for Red, Green, Blue assuming MicaSense band order: Blue, Green, Red, RedEdge, NIR)
#' @param class_colors Named list mapping remapped class values to hex colors
#' @param output_dir Directory to write TIFFs (default: data_dir)
#' @param overlay_alpha Transparency for class overlay, 0-1 (default 0.5)
#' @returns Invisible vector of output file paths
#' @importFrom reticulate import
#' @export


draw_patches <- function(data_dir, site, dataset = 'train', n = 5, patchno = NULL,
                         rgb_channels = c(3, 2, 1),
                         class_colors = NULL, output_dir = NULL, 
                         overlay_alpha = 0.5) {
   
   
   np <- reticulate::import('numpy')
   
   if (is.null(output_dir)) output_dir <- data_dir
   dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
   
   
   # ---- Load numpy arrays ----
   patches <- as.array(np$load(file.path(data_dir, paste0(site, '_', dataset, '_patches.npy'))))
   labels  <- as.array(np$load(file.path(data_dir, paste0(site, '_', dataset, '_labels.npy'))))
   masks   <- as.array(np$load(file.path(data_dir, paste0(site, '_', dataset, '_masks.npy'))))

   n_patches <- dim(patches)[1]
   patch_h <- dim(patches)[2]
   patch_w <- dim(patches)[3]
   n_channels <- dim(patches)[4]
   
   message('Loaded ', n_patches, ' ', dataset, ' patches: ', 
           patch_h, 'x', patch_w, ', ', n_channels, ' channels')
   
   
   # ---- Default class colors (water model) ----
   if (is.null(class_colors)) {
      class_colors <- list(
         '0' = '#7293c9',    # 21 Ditch (remapped to 0)
         '1' = '#3a52c9',    # 22 Creek (remapped to 1)
         '2' = '#00aec5',    # 25 Pool (remapped to 2)
         '3' = '#eee9e9'     # 99 Background (remapped to 3)
      )
      message('Using default water model colors (21=Ditch, 22=Creek, 25=Pool, 99=Background)')
      message('Pass class_colors if using a different classification')
   }
   
   
   # ---- Select patches ----
   if (!is.null(patchno)) {
      idx <- patchno
      if (any(idx > n_patches | idx < 1))
         stop('patchno values must be between 1 and ', n_patches)
   } else {
      # Pick patches with good class diversity
      # Score each patch by number of distinct classes present in masked area
      scores <- sapply(1:n_patches, function(i) {
         masked_labels <- labels[i, , ][masks[i, , ] == 1]
         masked_labels <- masked_labels[masked_labels != 255]
         length(unique(masked_labels))
      })
      
      # Prefer patches with more classes; random within top scorers
      top_score <- max(scores)
      candidates <- which(scores >= max(top_score - 1, 1))  # top tier and one below
      set.seed(42)
      idx <- sort(base::sample(candidates, min(n, length(candidates))))
      message('Selected ', length(idx), ' patches (class diversity scores: ', 
              paste(scores[idx], collapse = ', '), ')')
   }
   
   
   # ---- Helper: hex to RGB ----
   hex2rgb <- function(hex) {
      hex <- sub('#', '', hex)
      c(strtoi(substr(hex, 1, 2), 16),
        strtoi(substr(hex, 3, 4), 16),
        strtoi(substr(hex, 5, 6), 16))
   }
   
   
   # ---- Write patches ----
   outfiles <- character(length(idx))
   
   for (j in seq_along(idx)) {
      i <- idx[j]
      
      # Extract RGB channels. patches are [N, H, W, C]; indexing one patch+channel gives [H, W].
 
      r <- patches[i, , , rgb_channels[1]]
      g <- patches[i, , , rgb_channels[2]]
      b <- patches[i, , , rgb_channels[3]]
      
      # Percentile stretch for display
      stretch <- function(band) {
         lo <- quantile(band, 0.02, na.rm = TRUE)
         hi <- quantile(band, 0.98, na.rm = TRUE)
         band <- (band - lo) / (hi - lo) * 255
         pmin(pmax(band, 0), 255)
      }
      
      r <- stretch(r)
      g <- stretch(g)
      b <- stretch(b)
      
      # Overlay class colors where mask == 1 (not transposed)
      lab <- labels[i, , ]
      msk <- masks[i, , ]
      
      for (cls in names(class_colors)) {
         cls_int <- as.integer(cls)
         cls_pixels <- (lab == cls_int) & (msk == 1)
         if (any(cls_pixels)) {
            col <- hex2rgb(class_colors[[cls]])
            alpha <- overlay_alpha
            r[cls_pixels] <- r[cls_pixels] * (1 - alpha) + col[1] * alpha
            g[cls_pixels] <- g[cls_pixels] * (1 - alpha) + col[2] * alpha
            b[cls_pixels] <- b[cls_pixels] * (1 - alpha) + col[3] * alpha
         }
      }
      
      # Stack into 3-band raster and write.
      # patches are now [H, W, C]; transpose each band so c() reads in raster
      # row-major order, which is what terra::values<- expects.
      rgb_array <- array(c(t(r), t(g), t(b)), dim = c(patch_w, patch_h, 3))
      
      rast_out <- terra::rast(nrows = patch_h, ncols = patch_w, nlyrs = 3,
                              xmin = 0, xmax = patch_w, ymin = 0, ymax = patch_h)
      terra::values(rast_out) <- rgb_array
      names(rast_out) <- c('Red', 'Green', 'Blue')
      
      fname <- file.path(output_dir, 
                         sprintf('patch_%s_%s_%04d.tif', site, dataset, i))
      terra::writeRaster(rast_out, fname, overwrite = TRUE, datatype = 'INT1U')
      outfiles[j] <- fname
      
      # Report class composition
      masked_labels <- lab[msk == 1]
      masked_labels <- masked_labels[masked_labels != 255]
      tab <- table(masked_labels)
      class_report <- paste(sprintf('%s:%d', names(tab), tab), collapse = ', ')
      message(sprintf('  Patch %04d -> %s  [classes: %s]', i, basename(fname), class_report))
   }
   
   message('\nWrote ', length(outfiles), ' patch TIFFs to ', output_dir)
   invisible(outfiles)
}