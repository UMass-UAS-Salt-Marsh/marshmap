#' Script to set up environment for parameters
#' 
#' The environment `the` is used for user parameters. They
#' are assigned by `init()`, which is run when the package is 
#' loaded, and also may be run by the user, e.g., which parameter
#' files are changed.
#' @export


the <- new.env(parent = emptyenv())
library(slurmcollie)
