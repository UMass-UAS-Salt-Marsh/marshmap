#' Put together site info message
#' 
#' @param sites Sites table
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @import shiny
#' @keywords internal


screen_site_info <- function(sites, input, output, session) {
   
   
   lays <- nrow(session$userData$db) - sum(session$userData$db$deleted) 
   scored <- sum(session$userData$db$score > 0, na.rm = TRUE)
   pct <- round(scored / lays * 100, 0)
   info <- paste0(' - ', scored, ' scored of ', lays, ' (', pct, '%)')
   renderText(paste0(sites$site_name[sites$site == input$site], info))
}