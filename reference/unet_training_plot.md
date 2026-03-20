# Plot U-Net training curves across cross-validations

Reads per-CV training metrics CSVs, computes a smoothed cross-validation
mean, and saves a ggplot2 figure. Individual CV curves are shown in
light pastel colors; the smoothed mean is shown as a bold black line.

## Usage

``` r
unet_training_plot(all_metrics, config, model_dir, site)
```

## Arguments

- all_metrics:

  List of data frames, one per CV, as returned by reading each
  `training_metrics.csv`.

- config:

  List of configuration parameters (uses `config$window` for the
  half-width of the centered rolling-mean smoother; default 1 = no
  smoothing).

- model_dir:

  Directory where the output PNG will be saved.

- site:

  3-letter site code (used only for the plot title).
