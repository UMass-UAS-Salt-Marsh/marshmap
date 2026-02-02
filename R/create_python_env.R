#' Create Python 3.10 env for U-Net
#' 
#' Rerun this when
#'  - new user or system
#'  - Python version changes
#'  - the environment gets corrupted
#'  
#' To install additional Python packages, use `virtualenv_install()`
#' @export


create_py_env <- function() {
   
   
   system('rm -rf ~/marshmap_env')                                            # Remove old environment
   
   reticulate::virtualenv_create(                                             # Create new one with Python 3.10 from R
      envname = '~/marshmap_env',
      python = '/usr/bin/python3.10'
   )

   reticulate::virtualenv_install(                                            # Install numpy <2.0 explicitly
      envname = "~/marshmap_env",
      packages = c("numpy<2.0", "scipy", "matplotlib", "pandas")
   )
   
   reticulate::virtualenv_install(                                            # Install torch separately (with CUDA support)
      envname = '~/marshmap_env',
      packages = c('torch', 'torchvision', 'torchaudio'),
      pip_options = c('--index-url', 'https://download.pytorch.org/whl/cu118')
   )
   
   reticulate::virtualenv_install(                                            # Install segmentation models
      envname = '~/marshmap_env',
      packages = 'segmentation-models-pytorch'
   )
}