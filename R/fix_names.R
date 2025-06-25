#' Fix errors and inconsistencies in orthophoto file names
#' 
#' File names for the salt marsh project have a number of errors and inconsistencies,
#' for example, both "Jun" and "June" are used in names. This function cleans up file
#' names prior to building the orthophoto database so seasons, sensors, etc. can be 
#' extracted without trouble. The file names are *not* changed on the disk.
#' 
#' Set name reassignments in `pars.yaml`. Reassignments are case-sensitive (filenames
#' are not case-sensitive in general, but we want to keep reassignments narrow). Any
#' part of the name that matches will be changed, so take care. Reassignments look 
#' like this, with the substring to replace on the left, and the new substring on the 
#' right:
#' 
#' ```
#' fixnames:
#'   - June: Jun              # dates should be 3 letters
#'   - Sept: Sep
#'   - RR: Red                # site with inconsistent naming
#'   - Zenmuse: X3            # sensor with multiple names
#'   - MidOut: Mid_Out        # tide stage with a modifier needs separation
#'   - MidIn: Mid_In
#' ```
#' 
#' This would change an orthophoto named `x01Sept20_RR_MidOut_Zenmuse_Ortho.tif` to
#' `x01Sep20_Red_Mid_Out_X3_Ortho.tif`.
#' 
#' @param files Vector of file names
#' @returns Vector of cleaned-up file names
#' @importFrom stringr str_replace_all
#' @export


fix_names <- function(files) {
   
   
   str_replace_all(files, unlist(unlist(the$fixnames)))
   
}