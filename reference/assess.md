# Assess a model fit from validation data

Provide a model assessment. Normally called by `fit`, but may be called
separately for models applied to new sites.

## Usage

``` r
assess(
  fitid = NULL,
  model = NULL,
  newdata = NULL,
  site = NULL,
  top_importance = 20,
  summary = TRUE,
  confusion = TRUE,
  importance = TRUE,
  freq = TRUE,
  quiet = FALSE
)
```

## Arguments

- fitid:

  id of a model in the fits database. If using this, omit `model`, as
  the model info will be extracted from the database.

- model:

  Only when called by do_fit; named list of:

  fit

  :   model fit object

  confuse

  :   Confusion matrix

  nvalidate

  :   Number of cases in validation set

  id

  :   Model id

  name

  :   Model name

- newdata:

  An alternate validation set (e.g., from a different site). Variables
  must conform with the original dataset.

- site:

  One or more site names, for display only

- top_importance:

  Number of variables to keep for variable importance

- summary:

  Print model summary info if TRUE

- confusion:

  Print the confusion matrix and complete statistics if TRUE

- importance:

  Print variable importance if TRUE

- freq:

  Print empirical class frequency table (number of cases from training
  and holdout data by class) if TRUE

- quiet:

  If TRUE, don't print anything; just silently return stuff

## Value

Invisibly, a named list of

- confusion:

  Confusion matrix and complete statistics

- importance:

  Variable importance data frame

## Details

Called by `do_fit`, but also may be called by the user. Either provide
`fitid` for the model you want to assess (the normal approach), or
`model`, a list with necessary arguments (the approach used by `do_fit`,
because the model is not yet in the database). When you call `assess`
from the console, the fits database is not updated with the new
assessment.

You may supply `newdata` to assess a model on sites different from what
the model was built on. `newdata` is a data frame that conforms to the
data the model was built on. (***how exactly***?)

Assessments are returned invisibly; by default, they are printed to the
console.

**Explanations**

***1. Model info***

- Model fit id and name, if supplied

- Number of variables fit

- Sample size for training and validation holdout set. The confusion
  matrix and all statistics are derived from the holdout set.

- Correct classification rate, the percent of cases that were predicted
  correctly.

- Kappa, a refined version of the CCR that takes the probability of
  chance agreement into account.

***2. Confusion matrix***

- Shows which classification errors were made. Values falling on the
  diagonal were predicted correctly.

***3. Overall statistics***

- *Accuracy* is the correct classification rate (also known as CCR), the
  percent of cases that fall on the diagonal in the confusion matrix.

- The *No Information Rate* is the CCR you'd get if you always bet the
  majority class.

- *Kappa* is a refined version of the CCR that takes the probability of
  chance agreement into account.

- *McNemar's test* only applies to two-class data.

***4. Statistics by class***

- Lists the following statistics for each of the subclasses. These all
  scale from 0 to 1, with 1 generally indicating higher performance
  (except for prevalence, detection rate, and detection prevalence).

  - *Precision*, the proportion of cases predicted to be in the class
    that actually were (true positives / (true positives + false
    positives))

  - *Recall*, the proportion of cases actually in the class that were
    predicted to be in the class (true positives / (true positives +
    false negatives))

  - *F1*, the harmonic mean of precision and recall; a combined metric
    of model performance

  - *Prevalence*, the proportion of all cases that are in this class

  - *Detection Rate*, the proportion of all cases that are correctly
    predicted to be in this class

  - *Detection Prevalence*, the proportion of all cases predicted to be
    in this class

  - *Balanced Accuracy*, mean of true positive rate and true negative
    rate; a combined metric of model performance

  - *AUC* (Area Under the Curve) is the probability that the model, for
    a particular class, when given a random case in the class and a
    random case from another class, will rate the case in the class
    higher. Unlike the other statistics, AUC is independent of the
    particular cutpoint chosen, and is telling us about the performance
    of the probabilities produced by the model.

***5. Variable importance***

- Scaled from 0 to 100, gives the relative contribution of each variable
  to the model fit. Less-important variables will be trimmed based on
  the top_importance option. Note that variables are imagery bands, not
  an entire orthoimage; thus, for instance, an RGB true color image
  represents three variables, any of which may come into the model
  separately.
