#' Summary stats for extracted patches
#' 
#' Hope to see single class patches < 80%.
#' 
#' @param patch_data Extracted patches from `unet_extract_training_patches`
#' @returns Data frame of stats for each patch (`patch_id`, `n_labeled`, `n_classes`,
#'    `dominant_class`, `purity`)
#' @keywords internal

 
unet_patch_stats <- function(patch_data) {
   
   
   results <- data.frame(
      patch_id = 1:dim(patch_data$patches)[1],
      n_labeled = NA,
      n_classes = NA,
      dominant_class = NA,
      purity = NA  # fraction of labeled pixels in dominant class
   )
   
   
   for (i in 1:nrow(results)) {
      labels <- patch_data$labels[i, , ]
      mask <- patch_data$masks[i, , ]
      
      labeled_pixels <- labels[mask == 1]
      labeled_pixels <- labeled_pixels[!is.na(labeled_pixels)]
      
      results$n_labeled[i] <- length(labeled_pixels)
      results$n_classes[i] <- length(unique(labeled_pixels))
      
      if (length(labeled_pixels) > 0) {
         class_counts <- table(labeled_pixels)
         results$dominant_class[i] <- as.numeric(names(class_counts)[which.max(class_counts)])
         results$purity[i] <- max(class_counts) / length(labeled_pixels)
      }
   }
   

   message('Patch composition summary')
   message('   Mean labeled pixels per patch: ', round(mean(results$n_labeled), 2))
   message('   Patches with single class: ', sum(results$n_classes == 1), 
       ' (', round(100 * sum(results$n_classes == 1) / nrow(results), 1), '%)')
   message('   Patches with multiple classes: ', sum(results$n_classes > 1),
       ' (', round(100 * sum(results$n_classes > 1) / nrow(results), 1), '%)')
   message('   Mean patch purity: ', round(mean(results$purity, na.rm = TRUE), 3))


   hist(results$purity, breaks = 20, main = 'Patch Purity Distribution',
        xlab = 'Purity (fraction of pixels in dominant class)')
   
   
   invisible(results)
}
