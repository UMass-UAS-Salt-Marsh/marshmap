# Assess two-stage hierarchical U-Net model

Assess two-stage hierarchical U-Net model

## Usage

``` r
unet_assess_hierarchical(
  stage1_model_path,
  stage2_model_path,
  data_dir,
  site,
  stage1_transitional_code = 103,
  stage2_classes = c(3, 4, 5),
  original_test_labels = NULL
)
```

## Arguments

- stage1_model_path:

  Path to stage 1 (platform) model

- stage2_model_path:

  Path to stage 2 (transitional refinement) model

- data_dir:

  Directory with test data

- site:

  Site code

- stage1_transitional_code:

  Stage 1 code for transitional class (e.g., 103)

- stage2_classes:

  Vector of stage 2 classes (e.g., c(3,4,5))

- original_test_labels:

  Optional: original fine-grained test labels for end-to-end assessment

## Value

List with stage1_cm, stage2_cm, combined_cm, and predictions
