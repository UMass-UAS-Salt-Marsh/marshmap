library(batchtools)

reg <- makeRegistry(file.dir = "cuda_repro_registry", seed = 42)
reg$cluster.functions <- makeClusterFunctionsSlurm("inst/scripts/slurm_minimal.tmpl")

batchMap(function(.) {
   reticulate::use_python(
      "/work/pi_bcompton_umass_edu/bcompton_umass_edu/marshmap_env/bin/python3",
      required = TRUE
   )
   torch <- reticulate::import("torch")
   list(cuda_available = torch$cuda$is_available(),
        torch_cuda_version = torch$version$cuda)
}, . = 1L)

submitJobs(resources = list(use_gpu = TRUE, memory = "4G", walltime = "00:05:00"))
waitForJobs()
print(loadResult(1))
