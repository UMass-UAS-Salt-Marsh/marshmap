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
