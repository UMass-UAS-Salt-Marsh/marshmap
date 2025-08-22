#' Read a parameter table
#' 
#' Given a parameter name the corresponds to tab-delimited file, read and return the file
#' 
#' @param name Parameter name
#' @returns Data frame of the parameter file
#' @importFrom utils read.table
#' @keywords internal


read_pars_table <- function(name) {
   
   
   if(!name %in% names(the))
      stop('Parameter ', name, ' not in ', file.path(the$parsdir, the$parsfile))
   f <- file.path(the$parsdir, the[[name]])
   if(!file.exists(f))
      stop('Parameter file ', f, ' not found')
   read.table(f, sep = '\t', header = TRUE, comment.char = '')
}