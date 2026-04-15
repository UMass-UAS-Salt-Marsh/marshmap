#' Make sure CUDA is available for GPU jobs
#' 
#' @param requirecuda If TRUE, job expects a GPU, so do the test. If FALSE, just return.
#' @param test If TRUE, does a print test to try to get a better failure error message
#' @keywords internal


cuda_check <- function(requirecuda, test = FALSE) {
   # ── CUDA check (fail fast before any slow prep work) ──────────────────────
   if(requirecuda) {
      
      
      torch <- reticulate::import('torch')

      if(test) {                    # If test, use tryCatch to see WHY it's returning False
         os <- reticulate::import('os')
         message('CUDA_VISIBLE_DEVICES: ', os$environ$get('CUDA_VISIBLE_DEVICES', '(not set)'))
         message('CUDA_DEVICE_ORDER: ',    os$environ$get('CUDA_DEVICE_ORDER',    '(not set)'))
         tryCatch({
            # Attempting to get the current device usually triggers the actual driver error
            device <- torch$cuda$current_device()
            print(device)
         }, error = function(e) {
            cat("Caught Error during CUDA initialization:\n")
            message(e$message)
            print(reticulate::py_last_error())
         })
      }
      if(!torch$cuda$is_available())
         stop('CUDA is not available but requirecuda = TRUE. Aborting before prep.')
      message('CUDA available: TRUE')
   }
}
