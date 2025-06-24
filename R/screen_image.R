#' Display the current image plus info
#' 
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
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
      
      row <- session$userData$sel[session$userData$index]
      
      output$image_name <- renderText(session$userData$db$name[row])
      
      updateSliderTextInput(inputId = 'score', 
                            selected = score_choices[session$userData$db$score[row] + 1])
      updateTextInput(inputId = 'comment', 
                      value = session$userData$db$comment[row])
      
      session$userData$full <- rast(file.path(session$userData$dir, session$userData$db$name[row]))
      bands <- nlyr(session$userData$full)
      fi <- c(session$userData$db$type[row], 
              session$userData$db$sensor[row], 
              session$userData$db$season[row], 
              session$userData$db$year[row], 
              session$userData$db$tide[row], 
              session$userData$db$tidemod[row])
      fi <- fi[!is.na(fi)]
   
      image_info <- paste0(bands, ' band', ifelse(bands > 1, 's', ''), ' | ', paste(fi, collapse = ' '))
      output$image_info <- renderText(image_info)
      
      output$inset1 <- NULL
      output$inset2 <- NULL
      output$full <- screen_plot('full', bands, input, output, session = getDefaultReactiveDomain())
   }
}
