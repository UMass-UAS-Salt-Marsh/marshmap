# Two-stage assessment
results <- unet_assess_hierarchical(
   stage1_model_path = "models/stage1_platform/unet_nor_best.pth",
   stage2_model_path = "models/stage2_transitional/unet_nor_best.pth",
   data_dir = "data/nor/unet/unet01",
   site = "nor",
   stage1_transitional_code = 103,
   stage2_classes = c(3, 4, 5),
   original_test_labels = test_labels_vector  # Fine-grained ground truth
)

# Access individual components
results$stage1_cm       # Platform classification performance
results$stage2_cm       # Transitional refinement (conditional on stage 1 correct)
results$combined_cm     # End-to-end accuracy