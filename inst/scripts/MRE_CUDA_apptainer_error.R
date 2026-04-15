# MRE: create marshmap Python venv inside r-rocker-ml-verse/4.4.3_cuda12.8.1+apptainer
# Run this from an R session started with that module loaded.
# 
# Notes:
# 
# - This must run inside the container — the R session needs to be started with
#   module load r-rocker-ml-verse/4.4.3_cuda12.8.1+apptainer already in effect
# - TMPDIR must point somewhere in /work; the default /tmp is too small for the
#   PyTorch wheels
# - torch.cuda.is_available() will only return True from a GPU node (Slurm job or
#   GPU interactive session), not a login node
# - The env argument to system2 replaces the whole environment, so on a real run
#   you'd want c(Sys.getenv(), paste0("TMPDIR=", tmpdir)) — but for the MRE the above
#   is sufficient to show the pattern


venv  <- "/work/pi_cschweik_umass_edu/bcompton_umass_edu/marshmap_env_rocker"
tmpdir <- "/work/pi_cschweik_umass_edu/bcompton_umass_edu/tmp"

dir.create(tmpdir, recursive = TRUE, showWarnings = FALSE)

# 1. Create the venv from the container's Python 3.12
system2("python3", c("-m", "venv", venv))

pip <- file.path(venv, "bin", "pip")

# 2. Install PyTorch with CUDA 12.4 wheels
system2(pip,
        c("install", "torch", "torchvision",
          "--index-url", "https://download.pytorch.org/whl/cu124"),
        env = paste0("TMPDIR=", tmpdir))

# 3. Install remaining dependencies
system2(pip,
        c("install", "numpy", "segmentation-models-pytorch",
          "coral-pytorch", "matplotlib", "pyyaml", "tqdm"),
        env = paste0("TMPDIR=", tmpdir))

# 4. Verify
py_script <- tempfile(fileext = ".py")
writeLines(c(
   "import torch",
   "print(torch.__version__)",
   "print(torch.cuda.is_available())"
), py_script)
system2(file.path(venv, "bin", "python3"), py_script)
