# Predict with trained U-Net model

Predict with trained U-Net model

## Usage

``` r
unet_predict(model_file, data_dir, site, dataset = "test")
```

## Arguments

- model_file:

  Path to trained model (.pth file)

- data_dir:

  Directory containing test numpy files

- site:

  Site name (e.g., 'rr')

- dataset:

  Which dataset to predict on ('test' or 'validate')

## Value

List with predictions, labels, masks, and probabilities
