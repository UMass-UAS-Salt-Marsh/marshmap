#' When there's no info for a site, disable controls and blank out info
#' 
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @import shiny
#' @importFrom shinyjs disable
#' @keywords internal


screen_no_site <- function(input, output, session) {
   
   
   output$image_name <- NULL
   output$image_info <- NULL
   output$full <- NULL                                                             
   output$inset1 <- NULL
   output$inset2 <- NULL
   updateSliderTextInput(inputId = 'score', selected = 1)
   updateCheckboxInput(inputId = 'repair', value = FALSE)
   updateTextInput(inputId = 'comment', value = '')
   output$image_no <- renderText('-- of 0')
   
   lapply(c('score', 'repair', 'comment', 'inset', 'first', 'previous', 'next_', 'last'), disable)
}
