#' Export prepared data to numpy arrays for Python
#' 
#' @param patch_data List from unet_extract_training_patches
#' @param split_indices List from unet_spatial_train_val_split
#' @param output_dir Directory to save numpy files
#' @param site Name for files (e.g., "site1")


unet_export_to_numpy <- function(patch_data, split_indices, output_dir, site) {

      
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
   np$save(file.path(output_dir, paste0(site, "_train_patches.npy")), 
           train_patches)
   np$save(file.path(output_dir, paste0(site, "_train_labels.npy")), 
           train_labels)
   np$save(file.path(output_dir, paste0(site, "_train_masks.npy")), 
           train_masks)
   
   np$save(file.path(output_dir, paste0(site, "_val_patches.npy")), 
           val_patches)
   np$save(file.path(output_dir, paste0(site, "_val_labels.npy")), 
           val_labels)
   np$save(file.path(output_dir, paste0(site, "_val_masks.npy")), 
           val_masks)
   
   # Save metadata as CSV
   train_meta <- patch_data$metadata[split_indices$train_idx, ]
   val_meta <- patch_data$metadata[split_indices$val_idx, ]
   train_meta$split <- "train"
   val_meta$split <- "val"
   
   all_meta <- rbind(train_meta, val_meta)
   write.csv(all_meta, file.path(output_dir, paste0(site, "_metadata.csv")), 
             row.names = FALSE)
   
   message("Exported to: ", output_dir)
   message("Train: ", nrow(train_patches), " patches")
   message("Val: ", nrow(val_patches), " patches")
}
