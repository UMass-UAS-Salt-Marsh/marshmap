#' Display plots for screen
#' 
#' importFrom terra rast plotRGB
#' importFrom sf st_read
#' importFrom shiny renderPlot
#' 
#' 
#' 
#' 
#' @keyword internal


screen_plot <- function(input, output, session) {
   
   session$userData$tiffs <- grep('Mica_Ortho', session$userData$tiffs, value = TRUE)
   
   if(length(session$userData$tiffs) == 0)
      return()
   
   
   data <- rast(file.path(session$userData$dir, session$userData$tiffs[1]))
   
   output$full <- renderPlot({
      plotRGB(data, 3, 2, 1, stretch = 'lin')
      lines(session$userData$footprint, lwd = 3, col = 'red')
   })
}