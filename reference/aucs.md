# Return multi-class AUC (Area Under the Curve) for ranger models from caret

To use this, you must do the following when training the model:

- Class names must be valid R variables, so not 1, 2, 3, ... They must
  still be factors.

- You'll need to supply the `trControl` option to train with the
  following: `control <- trainControl(`  
  ` allowParallel = TRUE,`  
  ` method = 'cv',`  
  ` number = 5,`  
  ` classProbs = TRUE,`  
  ` savePredictions = 'final'`  
  `)`

If class levels all end in numbers (e.g., `class1`, `class`, `class3`),
the result will be sorted by the numbers so you won't get crap like
`class1`, `class10`, `class100`.

## Usage

``` r
aucs(fit, sort = TRUE)
```

## Arguments

- fit:

  Model fit from `train`

- sort:

  If TRUE, sort classes by trailing number

## Value

A vector with the AUC for each class
