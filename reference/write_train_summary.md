# Write summary.txt for a training run

Write summary.txt for a training run

## Usage

``` r
write_train_summary(model, train, fit_dir, config, cm, cv_ccr, fitid = NULL)
```

## Arguments

- model:

  Model name (base name of the .yml file)

- train:

  Train file name, or NULL

- fit_dir:

  Full path to the results directory

- config:

  Config list (merged model + train parameters)

- cm:

  caret confusionMatrix object (combined across all CVs)

- cv_ccr:

  Numeric vector of per-CV test CCR (0-1 scale)
