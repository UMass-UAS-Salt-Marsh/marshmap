#' Screen imagery for salt marsh project
#'
#' @import shiny
#' @import bslib
#' @importFrom shinybusy add_busy_spinner
#' @import shinyWidgets
#' @export




screen <- function() {
    
    sites <- (read_pars_table('sites'))
    sites$footprint <- basename(sites$footprint)
    
    
    # User interface ---------------------
    ui <- fluidPage(
        
        #  theme = bs_theme(bootswatch = 'cosmo', version = 5),                                   # version defense. Use version_default() to update
        
        includeCSS('www/styles.css'),
        div(class = 'container-fluid',
            add_busy_spinner(spin = 'fading-circle', position = 'bottom-right', onstart = FALSE, timeout = 500),
            
            
            fluidRow(
                class = 'fullheight',
                
                column(6, class = 'col-fullheight',
                       plotOutput('full', height = '100%')
                ),
                
                column(3, class = 'col-fullheight',
                       div(class = 'center-flex',
                           
                           div(class = 'center-inset',
                               plotOutput('inset1', height = '100%')
                           ),
                           
                           div(class = 'center-inset',
                               plotOutput('inset2', height = '100%')
                           )
                       )
                ),
                
                column(3, class = 'col-fullheight',
                       
                       titlePanel('Salt marsh imagery screener'),
                       
                       selectInput('site', label = 'Site', choices = sites$site),
                       
                       sliderInput('period', label = 'Something', min = 0, max = 0, value = c(0, 0)),
                       
                       materialSwitch('grab', label = 'Do this', value = FALSE),
                       
                       actionButton('inset', 'Show insets')
                )
            )
        )
    )
    
    
    
    # Server -----------------------------
    server <- function(input, output, session) {
        
        # bs_themer()                                                                               # uncomment to select a new theme
        
        observeEvent(input$site, {
            session$userData$dir <- resolve_dir(the$flightsdir, input$site)
            
            footfile <- file.path(resolve_dir(the$shapefilesdir, input$site), sites$footprint[sites$site == input$site])
            session$userData$footprint <- st_read(footfile, quiet = TRUE)    
            
            session$userData$tiffs <- grep('.tif$', list.files(session$userData$dir), value = TRUE)
            session$userData$tiffs <- grep('Mica_Ortho', session$userData$tiffs, value = TRUE)
            
            session$userData$full <- rast(file.path(session$userData$dir, session$userData$tiffs[1]))
            
            output$inset1 <- NULL
            output$inset2 <- NULL
            output$full <- screen_plot('full', input, output, session = getDefaultReactiveDomain())
            
        })
        
        observeEvent(input$inset, {
            session$userData$inset1 <- center_zoom(session$userData$full, 0.1)
            output$inset1 <- screen_plot('inset1', input, output, session = getDefaultReactiveDomain())
            
            session$userData$inset2 <- center_zoom(session$userData$full, 0.01)
            output$inset2 <- screen_plot('inset2', input, output, session = getDefaultReactiveDomain())
            
        })
    }
    
    
    shinyApp(ui = ui, server = server)
}
