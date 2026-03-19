# Train and assess U-Net model

Train a U-Net model. Result files are placed in `<site>/unet/<model>`.

## Usage

``` r
train(
  model,
  train = "train",
  result = NULL,
  resources = NULL,
  local = FALSE,
  trap = TRUE,
  comment = NULL
)
```

## Arguments

- model:

  The base name of a `.yml` file in `<pars>/unet/` with model
  parameters. This file contains parameters used in data prep as well as
  training. Note that `prep_unet` must be run after changing any of
  these parameters. The `model` file must contain the following:

  - site: the three-letter site code

  - years: the year(s) of field data to fit

  - orthos: file names of all orthophotos to include

  - patch: size in pixels

  - depth: number of of downsampling stages

  - classes: vector of target classes (in original classification)

  - holdout_col: holdout set to use (uses bypoly). Holdout sets are
    created by `gather`, numbering each poly from 1 to 10, repeating if
    necessary. There are 5 sets to choose from.

  - cv: number of cross-validations. Use 1 for a single model, up to 5
    for five-fold cross-validation. Cross-validations are systematic,
    not random. Since there are only 10 sets in each bypoly, the number
    of cross-validations is limited by the values of val and test.

  - val: validation polys from `holdout_col`. Use NULL to skip
    validation, or a vector of the validation polys for the first
    cross-validation (these will be incremented for subsequent
    validations). For 20% validation holdout, use `val = c(1, 6)`. This
    will use
    ``` bypoly01 %in% c(1,6)`` for the first cross-validation,  ```c(2,
    7)\` for the second, and so on.

  - test: test polys from `holdout_col`, as with `val`.

  - overlap: Proportion overlap of patches

  - upscale: number of cells to upscale (default = 1). Use 3 to upscale
    to 3x3, 5 for 5x5, etc.

  - smooth: number of cells to include in moving window mean (default =
    1). Use 3 to smooth to 3x3, etc.

- train:

  The base name of a `.yml` file in `<pars>/unet/` with training
  parameters. If present, this overrides parameters in `model`. This
  file contains parameters used only in the training phase. The
  following must be present either in the `model` or `train` file:

  - in_channels Number of input channels (8 for multispectral + NDVI +
    NDRE + DEM)

  - n_epochs Number of training epochs

  - encoder_name. Pre-trained encoder to use. Choices include
    `resnet10`, `resnet18`, `resnet34`, `resnet50`, `efficientnet-b0`,
    and others. The lower `restnet` numbers have fewer parameters, so
    may be likely to result in more stable training.

  - encoder_weights. `imagenet` start with weights learned on ImageNet
    (natural images); gives faster convergence, but might bias toward
    RGB patterns. NULL starts with random initialization, thus learns
    everything from this dataset; no bias, but slower training.

  - learning_rate Learning rate for optimizer

  - weight_decay. L2 regularization - penalizes large weights to prevent
    overfitting. Higher values (1e-3) = stronger regularization. Lower
    values (1e-5) = weaker.

  - class_weighting. One of `none`, `freq`, or `sqrt`. If `none`, all
    classes will be given the same weight; `freq` weights them by
    inverse frequency, and `sqrt` weights by the square root of the
    inverse frequency.

  - batch_size. How many patches to process together. Larger (16, 32)
    uses parallelization on GPUs so trains faster, more stable
    gradients, uses more GPU memory. Smaller (4, 8) gives noisier
    gradients (good regularization), less memory, better for small
    datasets. Use 8; if overfitting is a problem, try 4.

  - gradient_clip_max_norm. Prevents exploding gradients by capping
    gradient magnitude. Range: 0.5 (aggressive clipping) to 5.0
    (gentle); start with 1.0.

  - use_ordinal If TRUE, use ordinal regression U-Net

- result:

  Name for this training run's result subdirectory. If NULL (default),
  automatically increments to the next available `fitNN` name (e.g.
  `"fit01"`, `"fit02"`). Specify explicitly to overwrite an existing
  run.

- resources:

  Slurm launch resources. See
  [launch](https://rdrr.io/pkg/slurmcollie/man/launch.html). These take
  priority over the function's defaults. **Note that this function
  requires GPUs**. By default, it requests 1 L40S (preferred), but will
  accept V100 or RTX 2080 Ti. To specify only L40S, use
  `resources = list(constraint = 'l40s')`.

- local:

  If TRUE, run locally; otherwise, spawn a batch run on Unity

- trap:

  If TRUE, trap errors in local mode; if FALSE, use normal R error
  handling. Use this for debugging. If you get unrecovered errors, the
  job won't be added to the jobs database. Has no effect if local =
  FALSE.

- comment:

  Optional slurmcollie comment
