# Fit models

Fit models

## Usage

``` r
do_fit(
  fitid,
  sites,
  name,
  method,
  fitargs,
  vars,
  exclude_vars,
  exclude_classes,
  include_classes,
  min_class,
  reclass,
  max_samples,
  years,
  minscore,
  maxmissing,
  max_miss_train,
  top_importance,
  holdout,
  bypoly,
  blocks,
  auc,
  hyper,
  notune,
  rep = NULL
)
```

## Arguments

- fitid:

  Fit id in the fits database

- sites:

  Data frame with `site` (3 letter code), `site_name` (long name), and
  `datafile` (resolved path and filename of datafile). Sites, paths, and
  filenames are vetted by fit - there's no checking here.

- name:

  Optional model name

- method:

  One of `rf` for Random Forest, `boost` for AdaBoost. Default = `rf`.

- fitargs:

  A named list of additional arguments to pass to the model (`ranger` or
  `boost`)

- vars:

  Vector of variables to restrict analysis to. Default = `{*}`, all
  variables. `vars` is processed by `find_orthos`, and may include file
  names, portable names, search names and regular expressions of file
  and portable names.

- exclude_vars:

  An optional vector of variables to exclude. As with `vars`, variables
  are processed by `find_orthos`

- exclude_classes:

  Numeric vector of subclasses to exclude. This overrides `fit_exclude`
  that may be included in `sites.txt`.

- include_classes:

  Numeric vector of subclasses to include - all other classes are
  dropped. `include_classes` overrides `fit_exclude` (in `sites.txt`)
  and `exclude_classes`.

- min_class:

  Minimum number of training samples to allow in a class. All classes
  with fewer samples in training set as well as all classes with zero
  cases in the validation set will be dropped from the model. Use
  `min_class = NULL` to prevent dropping any classes.

- reclass:

  Matrix or vector of paired classes to reclassify. Pass either a two
  column matrix, such that values in the first column are reclassifed to
  the second column, or a vector with pairs, `reclass = c(13, 2, 3, 4)`,
  which would reclassify all 13s to 2 and 3s to 4, lumping each pair of
  classes. Reclassifying is not iterative, thus you could swap 1s and 2s
  with `reclass = c(1, 2, 2, 1)`, not that you'd want to.

- max_samples:

  Maximum number of samples to use - subsample if necessary

- years:

  Vector of years to restrict variables to

- minscore:

  Minimum score for orthos. Files with a minimum score of less than this
  are excluded from results. Default is 0, but rejected orthos are
  always excluded.

- maxmissing:

  Maximum percent missing in orthos. Files with percent missing greater
  than this are excluded.

- max_miss_train:

  Maximum proportion of missing training points allowed before a
  variable is dropped

- top_importance:

  Number of variables to keep for variable importance

- holdout:

  Proportion of points to hold out. For Random Forest, this specifies
  the size of the single validation set, while for boosting, it is the
  size of each of the testing and validation sets.

- bypoly:

  The name of a `bypoly` cross-validation sequence in the sampled data.
  `gather` creates `bypoly01` through `bypoly05`, with sequences of 1:10
  for each subclass. Poly groups 1 and 6 will be used as holdouts. To
  specify different groups, use
  `blocks = list(block = 'bypoly01', classes = c(2, 7)`, for instance.

- blocks:

  An alternative to holding out random points. Specify a named list with
  `block = <name of block column>, classes = <vector of block classes to hold out>`.
  Set this up by creating a shapefile corresponding to ground truth data
  with a variable `block` that contains integer block classes, and
  placing it in the `blocks/` directory for the site. `gather` and
  `sample` will collect and process block data for you to use here.

- auc:

  If TRUE, calculate class probabilities so we can calculate AUC

- hyper:

  Hyperparameters ***To be defined***

- notune:

  If TRUE, don't do hyperparameter tuning. This can cost you a few
  percent in CCR, but will speed the run up six-fold from the default.

- rep:

  Throwaway argument to make `slurmcollie` happy
