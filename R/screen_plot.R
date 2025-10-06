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


screen_plot <- function(extent, input, output, session) {
   
   
   row <- session$userData$sel[session$userData$index]
   cachedir <- file.path(session$userData$dir, 'cache')
   cache <- file.path(cachedir, paste0(file_path_sans_ext(session$userData$db$name[row]), '_', extent, '.png'))
   
   renderImage({
      list(src = cache,
           contentType = 'image/png')
   }, 
   deleteFile = FALSE)
}
