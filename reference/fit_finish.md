# Finish fit run

Finish a fit run:

- Populate fits database with `slurmcollie` stats

- and with info from `zz_<id>_fit.RDS`, written by `do_fit`

- Copy the log file to the models directory

## Usage

``` r
fit_finish(jobid, status)
```

## Arguments

- jobid:

  Job id to finish for

- status:

  Job status
