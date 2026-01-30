#' Export prepared data to numpy arrays for Python
#' 
#' @param patches List from unet_extract_training_patches
#' @param split_indices List from unet_spatial_train_validate_split
#' @param output_dir Directory to save numpy files
#' @param site Name for files (e.g., 'site1')
#' @importFrom reticulate import
#' @keywords internal


unet_export_to_numpy <- function(patches, split_indices, output_dir, site) {

   # ---------------------- done to here ----------------------
   browser()
   
   
   
   dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
   
   np <- import('numpy')                                                   # import Python's numpy module into R
   
   
   # Train data
   train_patches <- patches$patches[split_indices$train_idx, , , ]
   train_labels <- patches$labels[split_indices$train_idx, , ]
   train_masks <- patches$masks[split_indices$train_idx, , ]
   
   # Validate data
   validate_patches <- patches$patches[split_indices$validate_idx, , , ]
   validate_labels <- patches$labels[split_indices$validate_idx, , ]
   validate_masks <- patches$masks[split_indices$validate_idx, , ]
   
   
   # Convert to numpy and save using numpy.save() in Python to create numpy binaries
   np$save(file.path(output_dir, paste0(site, '_train_patches.npy')), 
           train_patches)
   np$save(file.path(output_dir, paste0(site, '_train_labels.npy')), 
           train_labels)
   np$save(file.path(output_dir, paste0(site, '_train_masks.npy')), 
           train_masks)
   
   np$save(file.path(output_dir, paste0(site, '_validate_patches.npy')), 
           validate_patches)
   np$save(file.path(output_dir, paste0(site, '_validate_labels.npy')), 
           validate_labels)
   np$save(file.path(output_dir, paste0(site, '_validate_masks.npy')), 
           validate_masks)
   

   message('Exported to: ', output_dir)
   message('Train: ', nrow(train_patches), ' patches')
   message('  - Patches: ', paste(dim(train_patches), collapse = 'x'))
   message('  - Labels: ', paste(dim(train_labels), collapse = 'x'))
   message('  - Masks: ', paste(dim(train_masks), collapse = 'x'))
   message('Val: ', nrow(validate_patches), ' patches')
   
   # Return file paths for verification
   invisible(list(
      train_patches = file.path(output_dir, paste0(site_name, '_train_patches.npy')),
      train_labels = file.path(output_dir, paste0(site_name, '_train_labels.npy')),
      train_masks = file.path(output_dir, paste0(site_name, '_train_masks.npy')),
      validate_patches = file.path(output_dir, paste0(site_name, '_validate_patches.npy')),
      validate_labels = file.path(output_dir, paste0(site_name, '_validate_labels.npy')),
      validate_masks = file.path(output_dir, paste0(site_name, '_validate_masks.npy')),
      metadata = file.path(output_dir, paste0(site_name, '_metadata.csv'))
   ))
}