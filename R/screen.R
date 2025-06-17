#' Screen imagery for salt marsh project
#'
#' import shiny
#' import bslib
#' import shinyWidgets
#' import terra
#' @export




screen <- function() {
    
    sites <- (read_pars_table('sites'))
    sites$footprint <- basename(sites$footprint)
    
    
    
    # User interface ---------------------
    ui <- page_sidebar(
        
        #    theme = bs_theme(bootswatch = 'cosmo', version = 5),                                   # version defense. Use version_default() to update
        
        title = 'Salt marsh imagery screener',
        
        
        sidebar = sidebar(position = 'right', 
                          
                          selectInput('site', label = 'Site', choices = sites$site),
                          
                          sliderInput('period', label = 'Something', min = 0, max = 0, value = c(0, 0)),
                          
                          materialSwitch('grab', label = 'Do this', value = FALSE),
        ),
        
        plotOutput('full')
        
    )
    
    
    
    # Server -----------------------------
    server <- function(input, output, session) {
        
        # bs_themer()                                                                               # uncomment to select a new theme
        
        observeEvent(input$site, {
            session$userData$dir <- resolve_dir(the$flightsdir, input$site)
            
            footfile <- file.path(resolve_dir(the$shapefilesdir, input$site), sites$footprint[sites$site == input$site])
            session$userData$footprint <- st_read(footfile, quiet = TRUE)    
            
            session$userData$tiffs <- grep('.tif$', list.files(session$userData$dir), value = TRUE)
            screen_plot(input, output, session = getDefaultReactiveDomain())
        })
    }
    
    
    shinyApp(ui = ui, server = server)
}
