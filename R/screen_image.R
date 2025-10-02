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
      lapply(c('score', 'comment', 'inset', 'first', 'previous', 'next_', 'last'), enable)
      
      
      output$image_no <- renderText(paste0(session$userData$index, ' of ', length(session$userData$sel),
                                           ifelse(input$filter != '', ' (filtered)', '')))
      
      row <- session$userData$sel[session$userData$index]
      
      output$image_name <- renderText(session$userData$db$name[row])
      
      updateSliderTextInput(inputId = 'score', 
                            selected = score_choices[session$userData$db$score[row] + 1])
      updateCheckboxInput(inputId = 'repair', value = session$userData$db$repair[row])
      updateTextInput(inputId = 'comment', 
                      value = session$userData$db$comment[row])
      
      sensor <- session$userData$db$sensor[row]
      # bands <- nlyr(session$userData$full)
      bands <- session$userData$db$bands[row]
      
      output$portable_name <- renderText(paste0(session$userData$db$portable[row], 
                                                ifelse(session$userData$db$dups[row] > 1,
                                                       paste0(' (',session$userData$db$dups[row], ')'),
                                                       '')))
      
      fi <- c(session$userData$db$type[row], 
              sensor, 
              session$userData$db$season[row], 
              session$userData$db$year[row], 
              ifelse(is.na(session$userData$db$tidemod[row]) || session$userData$db$tidemod[row] == '', 
                     session$userData$db$tide[row],
                     paste(session$userData$db$tide[row], session$userData$db$tidemod[row], sep = '-'))
      )
      
      fi <- fi[!(is.na(fi) | fi == '')]
      
      image_info <- paste0(bands, ' band', ifelse(bands > 1, 's', ''), '<br>', paste(fi, collapse = ' | '))
      output$image_info <- renderUI(HTML(image_info))
      
      output$inset1 <- NULL
      output$inset2 <- NULL
      output$full <- screen_plot('full', input, output, session = getDefaultReactiveDomain())
   }
}
