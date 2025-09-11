#' Filter/refilter images
#' 
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @import shiny
#' @keywords internal


screen_filter <- function(input, output, session) {
   
   
   sel <- !session$userData$db$deleted                                                             #    image list starts with everything that's not deleted
   sel <- sel & (input$revisit | (session$userData$db$score == 0 & !session$userData$db$repair))   #    exclude visited and repair unless revisit is selected
   
   if(input$filter != '')
      suppressWarnings(tryCatch({
         sel <- sel & (grepl(input$filter, session$userData$db$name, ignore.case = TRUE) |
                          grepl(input$filter, session$userData$db$portable, ignore.case = TRUE))   #    apply filter - now we have our complete list of images for this site
      },    
      error = function(cond) {
         showModal(modalDialog(
            title = 'Error', 
            paste0('Error in regular expression: ', input$filter),
            footer = modalButton('OK'),
            easyClose = TRUE
         ))  
         return()
      }))
   
   session$userData$sel <- (1:length(session$userData$db$name))[sel]                               #    indices of selected files in database
}
