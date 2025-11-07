# Clean up confusion matrix and associated stats

Cleans up the confusion matrix from a caret/ranger model fit:

- If class names are numeric:

  - include only the number in the confusion matrix and sort numerically

  - change the labels to `Class <number>` in the `byClass` table and
    sort numerically

- Round the `byClass` table to 4 digits, which is more than plenty!

- Optionally add a row for AUC to the `byClass` table. If the model
  hasn't been run with the necessary data for AUC, a message will be
  displayed and the row won't be added.

## Usage

``` r
unconfuse(confuse, auc = TRUE, fit = NULL)
```

## Arguments

- confuse:

  Confusion matrix

- auc:

  If TRUE, add AUC to the `byClass` table

- fit:

  A `ranger` model object (only needed if `auc` = TRUE)

## Value

A new model object with the confusion matrix cleaned up

## Details

Print the resulting table with `print(confuse, mode = 'prec_recall')`.
