# Build statistical models of vegetation cover

Given one or more sites and a model specification, builds a model of
vegetation cover and report model assessment.

## Usage

``` r
fit(
  site = NULL,
  datafile = "data",
  name = "",
  method = "rf",
  vars = "{*}",
  exclude_vars = "",
  exclude_classes = NULL,
  reclass = c(13, 2),
  max_samples = NULL,
  years = NULL,
  minscore = 0,
  maxmissing = 20,
  max_miss_train = 0.2,
  top_importance = 20,
  holdout = 0.2,
  blocks = NULL,
  auc = FALSE,
  hyper = NULL,
  resources = NULL,
  local = FALSE,
  trap = TRUE,
  comment = NULL
)
```

## Arguments

- site:

  Three letter site code, or vector of site names if fitting multiple
  sites

- datafile:

  Name of data file. It must be an `.RDS` file, but exclude the
  extension. If fitting multiple sites, either use a single datafile
  name shared among sites, or a vector matching site.

- name:

  Optional model name

- method:

  One of `rf` for Random Forest, `boost` for AdaBoost. Default = `rf`.

- vars:

  Vector of variables to restrict analysis to. Default = `{*}`, all
  variables. `vars` is processed by `find_orthos`, and may include file
  names, portable names, search names and regular expressions of file
  and portable names.

- exclude_vars:

  An optional vector of variables to exclude. As with `vars`, variables
  are processed by `find_orthos`

- exclude_classes:

  Numeric vector of subclasses to exclude

- reclass:

  Vector of paired classes to reclassify, e.g.,
  `reclass = c(13, 2, 3, 4)` would reclassify all 13s to 2 and 4s to 3,
  lumping each pair of classes.

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

  Hyperparameters. ***To be defined.***

- resources:

  Slurm launch resources. See
  [launch](https://rdrr.io/pkg/slurmcollie/man/launch.html). These take
  priority over the function's defaults.

- local:

  If TRUE, run locally; otherwise, spawn a batch run on Unity

- trap:

  If TRUE, trap errors in local mode; if FALSE, use normal R error
  handling. Use this for debugging. If you get unrecovered errors, the
  job won't be added to the jobs database. Has no effect if local =
  FALSE.

- comment:

  Optional launch / slurmcollie comment
