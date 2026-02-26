#' Environment for package parameters
#'
#' The environment `the` is used for user parameters. They
#' are assigned by `init()`, which is run when the package is
#' loaded, and also may be run by the user, e.g., when parameter
#' files are changed.
#' @name the
#' @export


if(exists('the'))                                        # delete the environment if it exists for a clean start
   rm('the', envir = as.environment(find('the')[1]))

the <- new.env(parent = emptyenv())
library(slurmcollie)
