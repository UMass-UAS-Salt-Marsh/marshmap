# Make sure CUDA is available for GPU jobs

Make sure CUDA is available for GPU jobs

## Usage

``` r
cuda_check(requirecuda, test = FALSE)
```

## Arguments

- requirecuda:

  If TRUE, job expects a GPU, so do the test. If FALSE, just return.

- test:

  If TRUE, does a print test to try to get a better failure error
  message
