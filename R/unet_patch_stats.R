#' Summary stats for extracted patches
#' 
#' Reports stats separately for train, val, and test masks.
#' Hope to see single class patches < 80%.
#' 
#' @param patch_data Extracted patches from `unet_extract_training_patches`
#' @returns List with train_stats, val_stats, and test_stats data frames
#' @keywords internal


unet_patch_stats <- function(patch_data) {
   
   
   n_patches <- dim(patch_data$patches)[1]
   
   # Stats for TRAIN masks
   train_results <- data.frame(
      patch_id = 1:n_patches,
      n_labeled = NA,
      n_classes = NA,
      dominant_class = NA,
      purity = NA
   )
   
   # Stats for VAL masks
   val_results <- data.frame(
      patch_id = 1:n_patches,
      n_labeled = NA,
      n_classes = NA,
      dominant_class = NA,
      purity = NA
   )
   
   # Stats for TEST masks
   test_results <- data.frame(
      patch_id = 1:n_patches,
      n_labeled = NA,
      n_classes = NA,
      dominant_class = NA,
      purity = NA
   )
   
   for (i in 1:n_patches) {
      labels <- patch_data$labels[i, , ]
      
      # TRAIN stats
      train_mask <- patch_data$train_masks[i, , ]
      train_labeled <- labels[train_mask == 1]
      train_labeled <- train_labeled[!is.na(train_labeled)]
      
      train_results$n_labeled[i] <- length(train_labeled)
      train_results$n_classes[i] <- ifelse(length(train_labeled) > 0, 
                                           length(unique(train_labeled)), 
                                           0)  # Set to 0 instead of leaving NA
      
      if (length(train_labeled) > 0) {
         class_counts <- table(train_labeled)
         train_results$dominant_class[i] <- as.numeric(names(class_counts)[which.max(class_counts)])
         train_results$purity[i] <- max(class_counts) / length(train_labeled)
      }
      
      # VAL stats
      val_mask <- patch_data$val_masks[i, , ]
      val_labeled <- labels[val_mask == 1]
      val_labeled <- val_labeled[!is.na(val_labeled)]
      
      val_results$n_labeled[i] <- length(val_labeled)
      val_results$n_classes[i] <- ifelse(length(val_labeled) > 0, 
                                         length(unique(val_labeled)), 
                                         0)  # Set to 0 instead of leaving NA
      
      if (length(val_labeled) > 0) {
         class_counts <- table(val_labeled)
         val_results$dominant_class[i] <- as.numeric(names(class_counts)[which.max(class_counts)])
         val_results$purity[i] <- max(class_counts) / length(val_labeled)
      }
      
      # TEST stats
      test_mask <- patch_data$test_masks[i, , ]
      test_labeled <- labels[test_mask == 1]
      test_labeled <- test_labeled[!is.na(test_labeled)]
      
      test_results$n_labeled[i] <- length(test_labeled)
      test_results$n_classes[i] <- ifelse(length(test_labeled) > 0, 
                                         length(unique(test_labeled)), 
                                         0)  # Set to 0 instead of leaving NA
      
      if (length(test_labeled) > 0) {
         class_counts <- table(test_labeled)
         test_results$dominant_class[i] <- as.numeric(names(class_counts)[which.max(class_counts)])
         test_results$purity[i] <- max(class_counts) / length(test_labeled)
      }
   }
   
   # Filter to patches that actually have data
   train_results <- train_results[patch_data$has_train, ]
   val_results <- val_results[patch_data$has_val, ]
   test_results <- test_results[patch_data$has_test, ]
   
   # Additional check: remove any with 0 or NA labeled pixels
   train_results <- train_results[!is.na(train_results$n_labeled) & train_results$n_labeled > 0, ]
   val_results <- val_results[!is.na(val_results$n_labeled) & val_results$n_labeled > 0, ]
   test_results <- test_results[!is.na(test_results$n_labeled) & test_results$n_labeled > 0, ]
   
   
   # Print summaries
   message('\n=== TRAINING PATCHES ===')
   message('   Total patches: ', nrow(train_results))
   message('   Mean labeled pixels per patch: ', round(mean(train_results$n_labeled, na.rm = TRUE), 2))
   message('   Patches with single class: ', sum(train_results$n_classes == 1, na.rm = TRUE), 
           ' (', round(100 * sum(train_results$n_classes == 1, na.rm = TRUE) / nrow(train_results), 1), '%)')
   message('   Patches with multiple classes: ', sum(train_results$n_classes > 1, na.rm = TRUE),
           ' (', round(100 * sum(train_results$n_classes > 1, na.rm = TRUE) / nrow(train_results), 1), '%)')
   message('   Mean patch purity: ', round(mean(train_results$purity, na.rm = TRUE), 3))
   
   message('\n=== VALIDATION PATCHES ===')
   message('   Total patches: ', nrow(val_results))
   message('   Mean labeled pixels per patch: ', round(mean(val_results$n_labeled, na.rm = TRUE), 2))
   message('   Patches with single class: ', sum(val_results$n_classes == 1, na.rm = TRUE), 
           ' (', round(100 * sum(val_results$n_classes == 1, na.rm = TRUE) / nrow(val_results), 1), '%)')
   message('   Patches with multiple classes: ', sum(val_results$n_classes > 1, na.rm = TRUE),
           ' (', round(100 * sum(val_results$n_classes > 1, na.rm = TRUE) / nrow(val_results), 1), '%)')
   message('   Mean patch purity: ', round(mean(val_results$purity, na.rm = TRUE), 3))
   
   message('\n=== TEST PATCHES ===')
   message('   Total patches: ', nrow(test_results))
   message('   Mean labeled pixels per patch: ', round(mean(test_results$n_labeled, na.rm = TRUE), 2))
   message('   Patches with single class: ', sum(test_results$n_classes == 1, na.rm = TRUE), 
           ' (', round(100 * sum(test_results$n_classes == 1, na.rm = TRUE) / nrow(test_results), 1), '%)')
   message('   Patches with multiple classes: ', sum(test_results$n_classes > 1, na.rm = TRUE),
           ' (', round(100 * sum(test_results$n_classes > 1, na.rm = TRUE) / nrow(test_results), 1), '%)')
   message('   Mean patch purity: ', round(mean(test_results$purity, na.rm = TRUE), 3))
   
   
   # Plot side by side
   par(mfrow = c(1, 3))
   hist(train_results$purity, breaks = 20, 
        main = 'Train Patch Purity',
        xlab = 'Purity (fraction in dominant class)',
        xlim = c(0, 1))
   hist(val_results$purity, breaks = 20, 
        main = 'Val Patch Purity',
        xlab = 'Purity (fraction in dominant class)',
        xlim = c(0, 1))
   hist(test_results$purity, breaks = 20, 
        main = 'Test Patch Purity',
        xlab = 'Purity (fraction in dominant class)',
        xlim = c(0, 1))
   par(mfrow = c(1, 1))
   
   invisible(list(
      train_stats = train_results,
      val_stats = val_results,
      test_stats = test_results
   ))
}
