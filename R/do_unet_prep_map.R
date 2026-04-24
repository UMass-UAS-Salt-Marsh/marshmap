#' Prepare map patches for U-Net prediction (worker)
#'
#' Tiles the full ortho extent (or a clipped region) into overlapping patches
#' ready for GPU prediction. Reuses `unet_build_input_stack()` to ensure
#' identical normalization to training. Saves numpy arrays, a patch-origin CSV,
#' and a nodata mask for later assembly.
#'
#' Output goes to `<site>/unet/<model>/map_patches/` (or
#' `map_patches_clip_<n>/` when clipped).
#'
#' @param model The model name (base name of the prep `.yml`)
#' @param clip Optional clip extent, vector of `xmin`, `xmax`, `ymin`, `ymax`
#' @importFrom yaml read_yaml
#' @importFrom terra rast crop ext res crs nlyr values nrow ncol
#' @importFrom reticulate import
#' @export


do_unet_prep_map <- function(model, clip = NULL) {
   
   
   config <- read_yaml(file.path(the$parsdir, 'unet', paste0(model, '.yml')))
   config$site <- tolower(config$site)                   # we want to use lowercase for site names
   
   MAP_OVERLAP <- if(!is.null(config$mapping_overlap)) config$mapping_overlap else 0.5
   
   config$fpath <- resolve_dir(the$flightsdir, config$site)
   config$bands <- unlist(lapply(config$orthos, function(x)
      nlyr(rast(file.path(config$fpath, x)))))
   config$n_channels <- sum(config$bands)
   
   config$type <- rep('image', length(config$orthos))
   config$type[grep('__NDVI', config$orthos)] <- 'ndvi'
   config$type[grep('__NDWIg', config$orthos)] <- 'ndwi'
   config$type[grep('__NDRE', config$orthos)] <- 'ndre'
   config$type[grep('DEM', config$orthos)] <- 'dem'
   config$type[config$type == 'image' & config$bands == 1] <- 'scalar'
   
   
   # ----- Output directory -----
   model_dir <- file.path(resolve_dir(the$unetdir, config$site), model)
   if(!is.null(clip)) {
      site_crs <- crs(rast(file.path(config$fpath, config$orthos[1])))
      clip_tag <- paste0('clip_', round(extent_area(clip, crs = site_crs)), '_ha')
      output_dir <- file.path(model_dir, paste0('map_patches_', clip_tag))
   }
   else {
      output_dir <- file.path(model_dir, 'map_patches')
   }
   
   
   # ----- Check if already done -----
   origins_file <- file.path(output_dir, 'patch_origins.csv')
   if(file.exists(origins_file)) {
      message('Map patches already exist at ', output_dir, '; skipping prep.')
      return(invisible(output_dir))
   }
   
   dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
   
   
   # ----- Build input stack (identical normalization to training) -----
   message('Building input stack for mapping...')
   input_stack <- unet_build_input_stack(config)
   
   if(!is.null(clip)) {
      message('Clipping to extent: ', paste(clip, collapse = ', '))
      input_stack <- crop(input_stack, ext(clip))
   }
   
   
   # ----- Calculate patch grid -----
   patch_size <- config$patch                                                  # pixels (e.g. 256)
   rez <- res(input_stack)[1]                                                  # cell size in map units
   patch_size_m <- patch_size * rez                                            # patch size in map units
   stride <- patch_size * (1 - MAP_OVERLAP)                                    # stride in pixels
   stride_m <- stride * rez                                                    # stride in map units
   
   rast_ext <- ext(input_stack)
   n_rows_rast <- nrow(input_stack)
   n_cols_rast <- ncol(input_stack)
   
   # Origins in pixel coordinates (0-indexed, top-left of each patch)
   col_origins <- seq(0, n_cols_rast - 1, by = stride)
   row_origins <- seq(0, n_rows_rast - 1, by = stride)
   
   # Ensure we cover the full extent (add a final patch at the edge if needed)
   if(tail(col_origins, 1) + patch_size < n_cols_rast)
      col_origins <- c(col_origins, n_cols_rast - patch_size)
   if(tail(row_origins, 1) + patch_size < n_rows_rast)
      row_origins <- c(row_origins, n_rows_rast - patch_size)
   
   # Remove duplicates and negatives
   col_origins <- sort(unique(pmax(col_origins, 0)))
   row_origins <- sort(unique(pmax(row_origins, 0)))
   
   # Build grid of all patch origins
   origins <- expand.grid(col = col_origins, row = row_origins)
   n_patches <- nrow(origins)
   
   message(sprintf('Tiling %d x %d raster into %d patches (%dx%d, %.0f%% overlap)',
                   n_cols_rast, n_rows_rast, n_patches,
                   patch_size, patch_size, MAP_OVERLAP * 100))
   
   
   # ----- Extract patches -----
   np <- import('numpy')
   n_channels <- nlyr(input_stack)
   
   patches <- array(0, dim = c(n_patches, patch_size, patch_size, n_channels))
   nodata_mask <- array(1L, dim = c(n_patches, patch_size, patch_size))        # 1 = valid, 0 = nodata
   
   # Convert full stack to array (careful: terra is row-major, R arrays are column-major)
   message('Reading full raster into memory...')
   full_vals <- values(input_stack, mat = TRUE)                                # (n_cells, n_channels)
   full_vals_array <- array(NA_real_, dim = c(n_rows_rast, n_cols_rast, n_channels))
   for(k in seq_len(n_channels))
      full_vals_array[, , k] <- matrix(full_vals[, k], nrow = n_rows_rast, 
                                       ncol = n_cols_rast, byrow = TRUE)
   
   # Track nodata: a pixel is nodata if ANY channel is NA
   full_nodata <- apply(full_vals_array, c(1, 2), function(x) any(is.na(x)))  # TRUE = nodata
   full_vals_array[is.na(full_vals_array)] <- 0                                # replace NA with 0 for model
   
   
   message('Extracting patches...')
   for(i in seq_len(n_patches)) {
      r0 <- origins$row[i] + 1                                                # 1-indexed for R
      c0 <- origins$col[i] + 1
      r1 <- min(r0 + patch_size - 1, n_rows_rast)
      c1 <- min(c0 + patch_size - 1, n_cols_rast)
      
      actual_h <- r1 - r0 + 1
      actual_w <- c1 - c0 + 1
      
      patches[i, 1:actual_h, 1:actual_w, ] <- full_vals_array[r0:r1, c0:c1, ]
      nodata_mask[i, 1:actual_h, 1:actual_w] <- as.integer(!full_nodata[r0:r1, c0:c1])
      
      # Edge padding stays as 0 (already initialized)
      if(actual_h < patch_size)
         nodata_mask[i, (actual_h + 1):patch_size, ] <- 0L                    # mark row padding as nodata
      if(actual_w < patch_size)
         nodata_mask[i, , (actual_w + 1):patch_size] <- 0L                    # mark column padding as nodata
      
      if(i %% 500 == 0)
         message(sprintf('  Processed %d / %d patches', i, n_patches))
   }
   
   rm(full_vals, full_vals_array, full_nodata)                                 # free memory
   
   
   # ----- Save -----
   message('Saving patches to ', output_dir, '...')
   
   np$save(file.path(output_dir, paste0(toupper(config$site), '_map_patches.npy')),
           np$array(patches, dtype = np$float32))                               # float32 halves file size vs R's default float64
   np$save(file.path(output_dir, paste0(toupper(config$site), '_map_nodata.npy')), nodata_mask)
   rm(patches, nodata_mask)
   gc()                                                                          # return memory to OS before returning to caller
   
   write.csv(origins, origins_file, row.names = FALSE)
   
   # Save metadata for predict and assemble
   meta <- list(
      site = config$site,
      model = model,
      n_patches = n_patches,
      patch_size = patch_size,
      overlap = MAP_OVERLAP,
      stride = as.integer(stride),
      n_channels = n_channels,
      n_rows_rast = n_rows_rast,
      n_cols_rast = n_cols_rast,
      rast_xmin = rast_ext$xmin,
      rast_xmax = rast_ext$xmax,
      rast_ymin = rast_ext$ymin,
      rast_ymax = rast_ext$ymax,
      resolution = rez,
      crs = as.character(crs(input_stack)),
      orthos = config$orthos,
      clip = if(!is.null(clip)) clip else 'none'
   )
   jsonlite::write_json(meta, file.path(output_dir, 'map_metadata.json'), 
                        auto_unbox = TRUE, pretty = TRUE)
   
   
   message(sprintf('Map prep complete: %d patches saved to %s', n_patches, output_dir))
   
   invisible(output_dir)
}
