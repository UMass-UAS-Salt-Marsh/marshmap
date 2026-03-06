#' Assess two-stage hierarchical U-Net model
#'
#' @param stage1_model_path Path to stage 1 (platform) model
#' @param stage2_model_path Path to stage 2 (transitional refinement) model  
#' @param data_dir Directory with test data
#' @param site Site code
#' @param stage1_transitional_code Stage 1 code for transitional class (e.g., 103)
#' @param stage2_classes Vector of stage 2 classes (e.g., c(3,4,5))
#' @param original_test_labels Optional: original fine-grained test labels for end-to-end assessment
#' @returns List with stage1_cm, stage2_cm, combined_cm, and predictions
#' @export


unet_assess_hierarchical <- function(stage1_model_path, stage2_model_path,
                                     data_dir, site,
                                     stage1_transitional_code = 103,
                                     stage2_classes = c(3, 4, 5),
                                     original_test_labels = NULL) {
   
   
   message('\n=== STAGE 1: PLATFORM CLASSIFICATION ===')
   
   # Predict with stage 1 model (6 platform classes)
   stage1_results <- unet_predict(
      model_path = stage1_model_path,
      data_dir = data_dir,
      site = site,
      dataset = 'test'
   )
   
   # Stage 1 confusion matrix
   stage1_cm <- unet_confusion_matrix(stage1_results)
   
   message('\nStage 1 Confusion Matrix:')
   print(stage1_cm)
   
   
   message('\n=== STAGE 2: TRANSITIONAL REFINEMENT ===')
   
   # Identify pixels predicted as transitional in stage 1
   transitional_mask <- stage1_results$predictions == stage1_transitional_code
   n_transitional <- sum(transitional_mask)
   
   message(sprintf('Stage 1 predicted %s pixels as transitional (%.1f%%)',
                   format(n_transitional, big.mark = ','),
                   100 * n_transitional / length(transitional_mask)))
   
   if (n_transitional == 0) {
      warning('No pixels predicted as transitional in Stage 1! Cannot run Stage 2.')
      return(list(
         stage1_cm = stage1_cm,
         stage2_cm = NULL,
         combined_cm = NULL,
         stage1_predictions = stage1_results$predictions
      ))
   }
   
   # Predict with stage 2 model (3 transitional subclasses)
   stage2_results <- unet_predict(
      model_path = stage2_model_path,
      data_dir = data_dir,
      site = site,
      dataset = 'test'
   )
   
   # Filter stage 2 predictions/labels to only transitional pixels
   # (where stage 1 correctly identified transitional AND truth is actually transitional)
   
   # Need to know which ground truth labels are transitional
   # Assuming original_test_labels or stage2 labels are in subclass space (3,4,5)
   truth_is_transitional <- stage2_results$labels %in% stage2_classes
   
   # Stage 2 assessment: only pixels where BOTH predicted AND actual are transitional
   valid_stage2 <- transitional_mask & truth_is_transitional
   
   if (sum(valid_stage2) == 0) {
      warning('No valid pixels for Stage 2 assessment (stage 1 never correctly predicted transitional)')
      stage2_cm <- NULL
   } else {
      # Create factors for confusion matrix
      stage2_pred_filtered <- factor(stage2_results$predictions[valid_stage2], 
                                     levels = stage2_classes)
      stage2_labels_filtered <- factor(stage2_results$labels[valid_stage2],
                                       levels = stage2_classes)
      
      stage2_cm <- caret::confusionMatrix(
         data = stage2_pred_filtered,
         reference = stage2_labels_filtered,
         mode = 'prec_recall'
      )
      
      message(sprintf('\nStage 2 assessment on %s correctly-identified transitional pixels:',
                      format(sum(valid_stage2), big.mark = ',')))
      print(stage2_cm)
   }
   
   
   message('\n=== COMBINED END-TO-END ASSESSMENT ===')
   
   # Combine stage 1 and stage 2 predictions
   combined_pred <- stage1_results$predictions  # Start with stage 1
   
   # Override transitional predictions with stage 2 refinement
   combined_pred[transitional_mask] <- stage2_results$predictions[transitional_mask]
   
   # For end-to-end assessment, need original fine-grained labels
   if (!is.null(original_test_labels)) {
      
      # Ensure factor levels match
      all_classes <- unique(c(combined_pred, original_test_labels))
      combined_pred_f <- factor(combined_pred, levels = all_classes)
      original_labels_f <- factor(original_test_labels, levels = all_classes)
      
      combined_cm <- caret::confusionMatrix(
         data = combined_pred_f,
         reference = original_labels_f,
         mode = 'prec_recall'
      )
      
      message('\nEnd-to-end confusion matrix (all classes):')
      print(combined_cm)
      
   } else {
      warning('No original_test_labels provided. Cannot compute end-to-end accuracy.')
      warning('End-to-end assessment requires ground truth in original fine-grained class space.')
      combined_cm <- NULL
   }
   
   
   # Return all results
   invisible(list(
      stage1_cm = stage1_cm,
      stage2_cm = stage2_cm,
      combined_cm = combined_cm,
      stage1_predictions = stage1_results$predictions,
      stage2_predictions = stage2_results$predictions,
      combined_predictions = combined_pred,
      transitional_mask = transitional_mask,
      n_transitional = n_transitional
   ))
}


#' Simple wrapper for single-stage assessment (existing behavior)
#' 
#' @param model_path Path to model
#' @param data_dir Data directory
#' @param site Site code
#' @param dataset Which dataset ('test' or 'validate')
#' @export

unet_assess <- function(model_path, data_dir, site, dataset = 'test') {
   
   results <- unet_predict(
      model_path = model_path,
      data_dir = data_dir,
      site = site,
      dataset = dataset
   )
   
   cm <- unet_confusion_matrix(results)
   
   print(cm)
   
   invisible(list(
      confusion_matrix = cm,
      predictions = results$predictions,
      labels = results$labels
   ))
}