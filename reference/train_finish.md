# Finish train run

Finish a U-Net train run:

- Populate fits database with `slurmcollie` stats

- and with info from `zz_<id>_train.RDS`, written by `do_train`

- Copy the log file to the models directory as `fit_<id>.log`

- Copy the log file to the unet model directory as `fit_<id>.log`

- Copy summary to `fit_<id>_summary.txt`

- Copy training curves to `fit_<id>_training_curves.png` (if present)

## Usage

``` r
train_finish(jobid, status)
```

## Arguments

- jobid:

  Job id to finish for

- status:

  Job status
