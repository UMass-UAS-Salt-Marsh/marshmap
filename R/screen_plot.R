#' Display plots for screen
#' 
#' @param extent Which plot to show, one of `full`, `inset1`, or `inset2`
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @importFrom terra rast plotRGB lines map.pal stretch
#' @importFrom sf st_read
#' @importFrom shiny renderPlot
#' @keywords internal


screen_plot <- function(extent, bands, input, output, session) {
   
   
   data <- switch(extent,
                  full = session$userData$full,
                  inset1 = session$userData$inset1,
                  inset2 = session$userData$inset2
   )
   
   
   renderPlot({
      if(bands == 1)
         plot(data, col = map.pal('bcyr'), legend = FALSE, axes = FALSE, mar = 0.5)
      else
         plotRGB(data, 3, 2, 1, stretch = 'lin', mar = 0.5)
      if(extent == 'full')
         lines(session$userData$footprint, lwd = 3, col = 'red')
   })
}
