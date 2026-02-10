# Predict with trained U-Net model

Predict with trained U-Net model

## Usage

``` r
unet_predict(
  model_path,
  data_dir,
  site,
  dataset = "test",
  num_classes = 4,
  in_channels = 8,
  class_mapping = c(`3` = 0, `4` = 1, `5` = 2, `6` = 3)
)
```

## Arguments

- model_path:

  Path to trained model (.pth file)

- data_dir:

  Directory containing test numpy files

- site:

  Site name (e.g., 'rr')

- dataset:

  Which dataset to predict on ('test' or 'validate')

- num_classes:

  Number of classes

- in_channels:

  Number of input channels

- class_mapping:

  Named vector mapping original to internal classes

## Value

List with predictions, labels, masks, and probabilities
