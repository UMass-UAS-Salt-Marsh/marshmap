#' Show inset images
#' 
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @keywords internal


screen_insets <- function(input, output, session) {
   
   
   output$inset1 <- screen_plot('inset1', input, output, 
                                session = getDefaultReactiveDomain())
   
   output$inset2 <- screen_plot('inset2', input, output, 
                                session = getDefaultReactiveDomain())
}