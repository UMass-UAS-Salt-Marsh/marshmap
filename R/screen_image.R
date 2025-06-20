#' Display the current image plus info
#' 
#' @import shiny
#' @importFrom shinyjs enable disable
#' @keywords internal


screen_image <- function(score_choices, input, output, session) {
   
   
   if(length(session$userData$sel) == 0)                                               # if no images selected,
      screen_no_site(input, output, session)
   else
   {
      lapply(c('score', 'comment', 'insets', 'first', 'previous', 'next_', 'last'), enable)
      
      
      output$image_no <- renderText(paste0(session$userData$index, ' of ', length(session$userData$sel)))
      
      output$image_name <- renderText(session$userData$db$name[session$userData$sel[session$userData$index]])
      
      updateSliderTextInput(inputId = 'score', 
                            selected = score_choices[session$userData$db$quality[session$userData$sel[session$userData$index]] + 1])
      updateTextInput(inputId = 'comment', 
                      value = session$userData$db$comment[session$userData$sel[session$userData$index]])
      
      session$userData$full <- rast(file.path(session$userData$dir, session$userData$db$name[session$userData$sel[session$userData$index]]))
      bands <- nlyr(session$userData$full)
      
   
      image_info <- paste0(bands, ' band', ifelse(bands > 1, 's', ''))
      output$image_info <- renderText(image_info)
      
      output$inset1 <- NULL
      output$inset2 <- NULL
      output$full <- screen_plot('full', bands, input, output, session = getDefaultReactiveDomain())
   }
}
