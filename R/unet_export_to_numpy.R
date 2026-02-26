#' Export prepared data to numpy arrays for Python
#' 
#' @param patches List from unet_extract_training_patches
#' @param output_dir Directory to save numpy files
#' @param site Name for files (e.g., 'rr')
#' @param class_mapping Named vector mapping original to remapped classes (e.g., c('3'=0, '4'=1, '5'=2, '6'=3))
#' @param set Cross-validation set (integer, typically 1:5)
#' @export


unet_export_to_numpy <- function(patches, output_dir, site, class_mapping, set) {
   
   
   if (!reticulate::py_module_available('numpy')) {
      stop('numpy not found. Run create_python_env() first.')
   }
   
   np <- reticulate::import('numpy')

   original_classes <- as.integer(names(class_mapping))              # Reverse mapping: 0->3, 1->4, 2->5, 3->6

   output_dir <- file.path(output_dir, paste0('set', set))           # include cross-validation set number as a subdirectory, e.g., 'set1'
   dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
   
   patches$train_masks[is.na(patches$labels)] <- 0                   # Where labels are NA, set mask to 0
   patches$val_masks[is.na(patches$labels)] <- 0
   patches$test_masks[is.na(patches$labels)] <- 0
   
   patches$labels[is.na(patches$labels)] <- 255                      # THEN replace NA labels with 255
   
   train_idx <- which(patches$has_train)                             # NOW extract train/val/test subsets
   val_idx <- which(patches$has_val)
   test_idx <- which(patches$has_test)
   
   
   message('\n=== EXPORTING PATCHES ===')
   message('Train patches: ', length(train_idx))
   message('Val patches: ', length(val_idx))
   message('Test patches: ', length(test_idx))
   message('Shared patches (train and val): ', sum(patches$has_train & patches$has_val, na.rm = TRUE))
   message('Shared patches (train and test): ', sum(patches$has_train & patches$has_test, na.rm = TRUE))
   message('Shared patches (val and test): ', sum(patches$has_val & patches$has_test, na.rm = TRUE))
   message('Shared patches (all three): ', sum(patches$has_train & patches$has_val & patches$has_test, na.rm = TRUE))
   
   
   # Train data
   train_patches <- patches$patches[train_idx, , , ]
   train_labels <- patches$labels[train_idx, , ]
   train_masks <- patches$train_masks[train_idx, , ]
   
   # Val data
   validate_patches <- patches$patches[val_idx, , , ]
   validate_labels <- patches$labels[val_idx, , ]
   validate_masks <- patches$val_masks[val_idx, , ]
   
   # Test data
   test_patches <- patches$patches[test_idx, , , ]
   test_labels <- patches$labels[test_idx, , ]
   test_masks <- patches$test_masks[test_idx, , ]
   
   
   # Replace NA
   train_labels[is.na(train_labels)] <- 255
   validate_labels[is.na(validate_labels)] <- 255
   test_labels[is.na(test_labels)] <- 255
   train_patches[is.na(train_patches)] <- 0
   validate_patches[is.na(validate_patches)] <- 0
   test_patches[is.na(test_patches)] <- 0
   
   
   # Quality checks
   cat('\nData quality:\n')
   cat('  Train mask coverage: ', round(mean(train_masks), 4), 
       ' (', round(mean(train_masks) * 100, 2), '% of pixels labeled)\n', sep='')
   cat('  Val mask coverage: ', round(mean(validate_masks), 4),
       ' (', round(mean(validate_masks) * 100, 2), '% of pixels labeled)\n', sep='')
   cat('  Test mask coverage: ', round(mean(test_masks), 4),
       ' (', round(mean(test_masks) * 100, 2), '% of pixels labeled)\n', sep='')
   
   
   # Count pixels by ORIGINAL class
   cat('\nTrain class distribution (labeled pixels only):\n')
   for (i in seq_along(original_classes)) {
      remapped <- class_mapping[as.character(original_classes[i])]
      n_pixels <- sum(train_labels == remapped & train_masks == 1)
      cat(sprintf('  Class %d: %s pixels\n', original_classes[i], format(n_pixels, big.mark=',')))
   }
   
   cat('\nVal class distribution (labeled pixels only):\n')
   for (i in seq_along(original_classes)) {
      remapped <- class_mapping[as.character(original_classes[i])]
      n_pixels <- sum(validate_labels == remapped & validate_masks == 1)
      cat(sprintf('  Class %d: %s pixels\n', original_classes[i], format(n_pixels, big.mark=',')))
   }
   
   cat('\nTest class distribution (labeled pixels only):\n')
   for (i in seq_along(original_classes)) {
      remapped <- class_mapping[as.character(original_classes[i])]
      n_pixels <- sum(test_labels == remapped & test_masks == 1)
      cat(sprintf('  Class %d: %s pixels\n', original_classes[i], format(n_pixels, big.mark=',')))
   }
   
   
   # Save
   np$save(file.path(output_dir, paste0(site, '_train_patches.npy')), train_patches)
   np$save(file.path(output_dir, paste0(site, '_train_labels.npy')), train_labels)
   np$save(file.path(output_dir, paste0(site, '_train_masks.npy')), train_masks)
   
   np$save(file.path(output_dir, paste0(site, '_validate_patches.npy')), validate_patches)
   np$save(file.path(output_dir, paste0(site, '_validate_labels.npy')), validate_labels)
   np$save(file.path(output_dir, paste0(site, '_validate_masks.npy')), validate_masks)
   
   np$save(file.path(output_dir, paste0(site, '_test_patches.npy')), test_patches)
   np$save(file.path(output_dir, paste0(site, '_test_labels.npy')), test_labels)
   np$save(file.path(output_dir, paste0(site, '_test_masks.npy')), test_masks)
   
   
   message('\nExported to: ', output_dir)
   
   invisible(list(
      train_patches = file.path(output_dir, paste0(site, '_train_patches.npy')),
      train_labels = file.path(output_dir, paste0(site, '_train_labels.npy')),
      train_masks = file.path(output_dir, paste0(site, '_train_masks.npy')),
      validate_patches = file.path(output_dir, paste0(site, '_validate_patches.npy')),
      validate_labels = file.path(output_dir, paste0(site, '_validate_labels.npy')),
      validate_masks = file.path(output_dir, paste0(site, '_validate_masks.npy')),
      test_patches = file.path(output_dir, paste0(site, '_test_patches.npy')),
      test_labels = file.path(output_dir, paste0(site, '_test_labels.npy')),
      test_masks = file.path(output_dir, paste0(site, '_test_masks.npy'))
      
   ))
}
