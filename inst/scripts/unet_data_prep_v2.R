# Claude's original code for U-Net data prep in R
# https://genai.umass.edu/share/MPIC0xsbJ9OaHX-vB-lHp
# 9 Dec 2025



# Section 1: Setup and Helper Functions

library(terra)
library(sf)
library(dplyr)
library(reticulate)

# Configuration
config <- list(
   patch = 256,  # pixels
   n_channels = 8,    # RGB + NIR + RedEdge + NDVI + NDRE + DEM                      <- get this from orthos
   classes = c(3, 4, 5, 6),  # Trans1, Trans2, Trans3, High1
   class_mapping = c("3" = 0, "4" = 1, "5" = 2, "6" = 3),  # Remap for U-Net         <- do this from classes
   holdout = 0.2,
   seed = 42
)

# Helper: Calculate NDVI
unet_calc_ndvi <- function(nir, red) {
   (nir - red) / (nir + red + 1e-8)  # epsilon to avoid division by zero
}

# Helper: Calculate NDRE
unet_calc_ndre <- function(nir, red_edge) {
   (nir - red_edge) / (nir + red_edge + 1e-8)
}

# Helper: Normalize raster to 0-1
unet_normalize_band <- function(r, method = "percentile", lower = 0.02, upper = 0.98) {
   if (method == "percentile") {
      vals <- values(r, na.rm = TRUE)
      q_lower <- quantile(vals, lower, na.rm = TRUE)
      q_upper <- quantile(vals, upper, na.rm = TRUE)
      r_norm <- (r - q_lower) / (q_upper - q_lower)
   } else if (method == "minmax") {
      r_norm <- (r - global(r, "min", na.rm = TRUE)[[1]]) / 
         (global(r, "max", na.rm = TRUE)[[1]] - global(r, "min", na.rm = TRUE)[[1]])
   }
   clamp(r_norm, lower = 0, upper = 1, values = TRUE)
}

# Helper: Standardize raster (mean=0, sd=1)
unet_standardize_band <- function(r) {
   r_mean <- global(r, "mean", na.rm = TRUE)[[1]]
   r_sd <- global(r, "sd", na.rm = TRUE)[[1]]
   (r - r_mean) / (r_sd + 1e-8)
}


# Section 2: Load and Stack Orthos

#' Build input stack for a given portable ortho name
#' 
#' @param portable_name e.g., "ortho_mica_fall_2022_high"
#' @param ortho_dir Directory containing ortho TIFFs
#' @param ortho_lookup Named vector mapping portable names to actual filenames
#' @return SpatRaster with 8 bands (RGB, NIR, RedEdge, NDVI, NDRE, DEM)


unet_build_input_stack <- function(portable_name, ortho_dir, ortho_lookup, dem_lookup) {

   
   
      
   # Get actual filename
   multispectral_file <- file.path(ortho_dir, ortho_lookup[[portable_name]])
   dem_file <- file.path(ortho_dir, dem_lookup[[portable_name]])
   
   # Load multispectral (assuming B-G-R-RedEdge-NIR order for 5-band)
   ms <- rast(multispectral_file)
   n_bands <- nlyr(ms)
   
   if (n_bands == 3) {
      # RGB only
      blue <- ms[[1]]
      green <- ms[[2]]
      red <- ms[[3]]
      nir <- NULL
      red_edge <- NULL
      message("Warning: RGB only, no NIR/RedEdge for ", portable_name)
      
   } else if (n_bands == 5) {
      # Full multispectral: B-G-R-RedEdge-NIR
      blue <- ms[[1]]
      green <- ms[[2]]
      red <- ms[[3]]
      red_edge <- ms[[4]]
      nir <- ms[[5]]
   } else {
      stop("Unexpected number of bands: ", n_bands)
   }
   
   # Load DEM
   dem <- rast(dem_file)
   
   # Normalize spectral bands to 0-1
   blue_norm <-unet_normalize_band(blue)
   green_norm <- unet_normalize_band(green)
   red_norm <- unet_normalize_band(red)
   
   if (!is.null(nir)) {
      nir_norm <- unet_normalize_band(nir)
      red_edge_norm <- unet_normalize_band(red_edge)
      
      # Calculate indices
      ndvi <- unet_calc_ndvi(nir, red)
      ndre <- unet_calc_ndre(nir, red_edge)
      
      # Clamp indices to reasonable range
      ndvi <- clamp(ndvi, lower = -1, upper = 1, values = TRUE)
      ndre <- clamp(ndre, lower = -1, upper = 1, values = TRUE)
      
      # Rescale indices from [-1,1] to [0,1] for consistency
      ndvi <- (ndvi + 1) / 2
      ndre <- (ndre + 1) / 2
      
   } else {
      # No NIR/RedEdge - use placeholders (zeros) or handle differently
      nir_norm <- blue_norm * 0
      red_edge_norm <- blue_norm * 0
      ndvi <- blue_norm * 0
      ndre <- blue_norm * 0
      message("Warning: Using zero placeholders for missing NIR/RedEdge")
   }
   
   # Standardize DEM
   dem_std <- unet_standardize_band_band(dem)
   
   # Stack all layers
   input_stack <- c(red_norm, green_norm, blue_norm, 
                    nir_norm, red_edge_norm, 
                    ndvi, ndre, dem_std)
   
   names(input_stack) <- c("red", "green", "blue", "nir", "red_edge", 
                           "ndvi", "ndre", "dem")
   
   return(input_stack)
}


# Section 3: Extract Patches from Transects

#' Extract training patches that overlap with transects
#' 
#' @param input_stack SpatRaster (8 bands)
#' @param transects sf object with ground truth polygons
#' @param patch Size of patches in pixels (e.g., 256)
#' @param overlap Overlap fraction between patches (e.g., 0.5 for 50%)
#' @return List containing patches (array), labels (array), masks (array), metadata (df)
unet_extract_training_patches <- function(input_stack, transects, patch = 256, 
                                     overlap = 0.5, classes = c(3,4,5,6),
                                     class_mapping = c("3"=0, "4"=1, "5"=2, "6"=3)) {
   
   # Filter to target classes
   transects <- transects %>% 
      filter(Subclass %in% classes)
   
   if (nrow(transects) == 0) {
      warning("No transects with target classes found")
      return(NULL)
   }
   
   # Reproject transects to match raster if needed
   transects <- st_transform(transects, crs(input_stack))
   
   # Get raster extent and resolution
   res_x <- res(input_stack)[1]
   patch_size_m <- patch * res_x
   step_size <- patch * (1 - overlap)
   
   # Create grid of potential patch centers
   ext <- ext(input_stack)
   x_centers <- seq(ext$xmin + patch_size_m/2, ext$xmax - patch_size_m/2, 
                    by = step_size * res_x)
   y_centers <- seq(ext$ymin + patch_size_m/2, ext$ymax - patch_size_m/2, 
                    by = step_size * res_x)
   
   patch_centers <- expand.grid(x = x_centers, y = y_centers)
   patch_centers_sf <- st_as_sf(patch_centers, coords = c("x", "y"), 
                                crs = crs(input_stack))
   
   # Filter to centers that intersect transects (with buffer)
   transects_buffered <- st_buffer(transects, dist = patch_size_m / 2)
   patch_centers_valid <- patch_centers_sf[st_intersects(patch_centers_sf, 
                                                         st_union(transects_buffered), 
                                                         sparse = FALSE), ]
   
   n_patches <- nrow(patch_centers_valid)
   message("Extracting ", n_patches, " patches...")
   
   # Initialize arrays
   patches <- array(NA, dim = c(n_patches, patch, patch, nlyr(input_stack)))
   labels <- array(NA, dim = c(n_patches, patch, patch))
   masks <- array(0, dim = c(n_patches, patch, patch))
   
   metadata <- data.frame(
      patch_id = 1:n_patches,
      center_x = st_coordinates(patch_centers_valid)[, 1],
      center_y = st_coordinates(patch_centers_valid)[, 2],
      n_labeled_pixels = NA,
      classes_present = NA
   )
   
   # Extract each patch
   for (i in 1:n_patches) {
      center <- st_coordinates(patch_centers_valid[i, ])
      
      # Define patch extent
      patch_ext <- ext(center[1] - patch_size_m/2, center[1] + patch_size_m/2,
                       center[2] - patch_size_m/2, center[2] + patch_size_m/2)
      
      # Crop input stack
      patch_rast <- crop(input_stack, patch_ext)
      
      # Convert to array [H, W, C]
      patch_array <- as.array(patch_rast)
      patch_array <- aperm(patch_array, c(2, 1, 3))  # terra gives [W, H, C], need [H, W, C]
      
      # Handle edge cases where patch is smaller than expected
      actual_h <- dim(patch_array)[1]
      actual_w <- dim(patch_array)[2]
      
      if (actual_h < patch || actual_w < patch) {
         # Pad with zeros
         padded <- array(0, dim = c(patch, patch, nlyr(input_stack)))
         padded[1:actual_h, 1:actual_w, ] <- patch_array
         patch_array <- padded
      }
      
      patches[i, , , ] <- patch_array
      
      # Rasterize transects to get labels
      transects_patch <- st_crop(transects, patch_ext)
      
      if (nrow(transects_patch) > 0) {
         # Create template raster
         template <- rast(patch_ext, nrows = patch, ncols = patch, 
                          crs = crs(input_stack))
         
         # Rasterize transects - use Subclass attribute
         label_rast <- rasterize(transects_patch, template, field = "Subclass")
         label_array <- as.matrix(label_rast, wide = TRUE)
         label_array <- label_array[nrow(label_array):1, ]  # flip vertically
         
         # Remap classes (3,4,5,6 -> 0,1,2,3)
         label_array_remapped <- label_array
         for (old_class in names(class_mapping)) {
            label_array_remapped[label_array == as.numeric(old_class)] <- 
               class_mapping[[old_class]]
         }
         
         # Create mask (1 where labeled, 0 where not)
         mask_array <- ifelse(is.na(label_array), 0, 1)
         
         labels[i, , ] <- label_array_remapped
         masks[i, , ] <- mask_array
         
         # Metadata
         metadata$n_labeled_pixels[i] <- sum(mask_array)
         metadata$classes_present[i] <- paste(unique(label_array_remapped[!is.na(label_array_remapped)]), 
                                              collapse = ",")
      }
   }
   
   # Filter out patches with no labeled pixels
   valid_patches <- metadata$n_labeled_pixels > 0
   
   message("Keeping ", sum(valid_patches), " patches with labels")
   
   return(list(
      patches = patches[valid_patches, , , ],
      labels = labels[valid_patches, , ],
      masks = masks[valid_patches, , ],
      metadata = metadata[valid_patches, ]
   ))
}


# Section 4: Train/Validation Split

#' Split patches into train and validation sets spatially
#' 
#' @param patch_data List from unet_extract_training_patches
#' @param transects Original sf transects object
#' @param holdout Fraction for validation (e.g., 0.2)
#' @param seed Random seed
#' @return List with train and val patch indices
unet_spatial_train_val_split <- function(patch_data, transects, holdout = 0.2, seed = 42) {
   
   set.seed(seed)
   
   # Get unique transect IDs (assuming they have an ID field, or use row number)
   if (!"transect_id" %in% names(transects)) {
      transects$transect_id <- 1:nrow(transects)
   }
   
   n_transects <- nrow(transects)
   n_val <- ceiling(n_transects * holdout)
   
   val_transect_ids <- sample(transects$transect_id, n_val)
   train_transect_ids <- setdiff(transects$transect_id, val_transect_ids)
   
   # Assign patches to train/val based on which transect they overlap most
   # (This is approximate - could be refined by checking actual overlap)
   
   # Simple approach: use spatial proximity
   patch_centers <- st_as_sf(patch_data$metadata, 
                             coords = c("center_x", "center_y"),
                             crs = st_crs(transects))
   
   # Find nearest transect for each patch
   nearest_transect <- st_nearest_feature(patch_centers, transects)
   patch_transect_ids <- transects$transect_id[nearest_transect]
   
   train_idx <- which(patch_transect_ids %in% train_transect_ids)
   val_idx <- which(patch_transect_ids %in% val_transect_ids)
   
   message("Train patches: ", length(train_idx))
   message("Val patches: ", length(val_idx))
   
   # Check class distribution
   train_classes <- unlist(strsplit(patch_data$metadata$classes_present[train_idx], ","))
   val_classes <- unlist(strsplit(patch_data$metadata$classes_present[val_idx], ","))
   
   message("Train class distribution: ", paste(table(train_classes), collapse = ", "))
   message("Val class distribution: ", paste(table(val_classes), collapse = ", "))
   
   return(list(
      train_idx = train_idx,
      val_idx = val_idx,
      train_transect_ids = train_transect_ids,
      val_transect_ids = val_transect_ids
   ))
}


# Section 5: Export to Numpy

#' Export prepared data to numpy arrays for Python
#' 
#' @param patch_data List from unet_extract_training_patches
#' @param split_indices List from unet_spatial_train_val_split
#' @param output_dir Directory to save numpy files
#' @param site_name Name for files (e.g., "site1")


unet_export_to_numpy <- function(patch_data, split_indices, output_dir, site_name) {

      
   dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
   
   np <- import("numpy")
   
   # Train data
   train_patches <- patch_data$patches[split_indices$train_idx, , , ]
   train_labels <- patch_data$labels[split_indices$train_idx, , ]
   train_masks <- patch_data$masks[split_indices$train_idx, , ]
   
   # Val data
   val_patches <- patch_data$patches[split_indices$val_idx, , , ]
   val_labels <- patch_data$labels[split_indices$val_idx, , ]
   val_masks <- patch_data$masks[split_indices$val_idx, , ]
   
   # Convert to numpy and save
   np$save(file.path(output_dir, paste0(site_name, "_train_patches.npy")), 
           train_patches)
   np$save(file.path(output_dir, paste0(site_name, "_train_labels.npy")), 
           train_labels)
   np$save(file.path(output_dir, paste0(site_name, "_train_masks.npy")), 
           train_masks)
   
   np$save(file.path(output_dir, paste0(site_name, "_val_patches.npy")), 
           val_patches)
   np$save(file.path(output_dir, paste0(site_name, "_val_labels.npy")), 
           val_labels)
   np$save(file.path(output_dir, paste0(site_name, "_val_masks.npy")), 
           val_masks)
   
   # Save metadata as CSV
   train_meta <- patch_data$metadata[split_indices$train_idx, ]
   val_meta <- patch_data$metadata[split_indices$val_idx, ]
   train_meta$split <- "train"
   val_meta$split <- "val"
   
   all_meta <- rbind(train_meta, val_meta)
   write.csv(all_meta, file.path(output_dir, paste0(site_name, "_metadata.csv")), 
             row.names = FALSE)
   
   message("Exported to: ", output_dir)
   message("Train: ", nrow(train_patches), " patches")
   message("Val: ", nrow(val_patches), " patches")
}


# Section 6: Main Workflow

#' Complete data preparation workflow for one site
#' 
#' Example usage for Site 1
unet_prepare_site_data <- function() {
   
   # Your file paths
   site_name <- "site1"
   ortho_dir <- "path/to/site1/orthos"
   transect_file <- "path/to/site1/transects.shp"
   output_dir <- "path/to/prepared_data/site1"
   
   # Define which ortho to use (your portable name)
   selected_ortho <- "ortho_mica_fall_2022_low"  # Example - pick your best one
   
   # Lookup tables (you'll need to create these for your data)
   # Map portable names to actual filenames
   ortho_lookup <- c(
      "ortho_mica_fall_2022_low" = "26Aug22_OTH_Low_Mica_Ortho.tif",
      # ... add all your orthos
   )
   
   dem_lookup <- c(
      "ortho_mica_fall_2022_low" = "26Aug22_OTH_Low_Mica_DEM.tif",
      # ... matching DEMs
   )
   
   # 1. Build input stack
   message("Building input stack...")
   input_stack <- unet_build_input_stack(selected_ortho, ortho_dir, 
                                    ortho_lookup, dem_lookup)
   
   # 2. Load transects
   message("Loading transects...")
   transects <- st_read(transect_file)
   
   # Filter to target classes
   transects <- transects %>% 
      filter(Subclass %in% config$classes)
   
   message("Transects with target classes: ", nrow(transects))
   
   # 3. Extract patches
   message("Extracting patches...")
   patch_data <- unet_extract_training_patches(
      input_stack = input_stack,
      transects = transects,
      patch = config$patch,
      overlap = 0.5,
      classes = config$classes,
      class_mapping = config$class_mapping
   )
   
   # 4. Train/val split
   message("Creating train/val split...")
   split_indices <- unet_spatial_train_val_split(
      patch_data = patch_data,
      transects = transects,
      holdout = config$holdout,
      seed = config$seed
   )
   
   # 5. Export to numpy
   message("Exporting to numpy...")
   unet_export_to_numpy(
      patch_data = patch_data,
      split_indices = split_indices,
      output_dir = output_dir,
      site_name = site_name
   )
   
   message("Data preparation complete!")
   
   return(list(
      patch_data = patch_data,
      split_indices = split_indices,
      input_stack = input_stack,
      transects = transects
   ))
}

# Run it
result <- unet_prepare_site_data()

