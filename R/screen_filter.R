#' Filter/refilter images
#' 
#' @import shiny
#' @keywords internal


screen_filter <- function(input, output, session) {
   
 
   sel <- !session$userData$db$deleted                                                             #    image list starts with everything that's not deleted
   sel <- sel & (input$revisit | session$userData$db$quality == 0)                                 #    exclude visited unless revisit is selected
   
   if(!is.null(input$filter))
      sel <- sel & grepl(input$filter, session$userData$db$name, ignore.case = TRUE)               #    apply filter - now we have our complete list of images for this site
   
   session$userData$sel <- (1:length(session$userData$db$name))[sel]                               #    indices of selected files in database
}
