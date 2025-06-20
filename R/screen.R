#' Screen imagery for salt marsh project
#'
#' @import shiny
#' @import bslib
#' @importFrom shinybusy add_busy_spinner
#' @import shinyWidgets
#' @importFrom terra rast nlyr
#' @export




screen <- function() {
    
    sites <- (read_pars_table('sites'))
    sites$footprint <- basename(sites$footprint)
    
    
    # User interface ---------------------
    ui <- fluidPage(
        
        theme = bs_theme(bootswatch = 'cerulean', version = 5),                                   # version defense. Use version_default() to update
        
        includeCSS('www/styles.css'),
        
#         tags$style(HTML("
# .selectize-dropdown {
#   position: relative !important;
# }
# ")),
        
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
                       
                       card(
                           selectInput('site', label = HTML('<h5 style="display: inline-block;">Site</h5>'), choices = sites$site, selectize = FALSE),
                           
                           materialSwitch(inputId = 'revisit', label = 'Revisit images', value = FALSE, 
                                          status = 'default'),
                           textInput('filter', HTML('<h6 style="display: inline-block;">Image filter</h6>'), value = '',
                                     width = '50%', placeholder = 'regex'),
                           
                           textOutput('site_info')
                       ),
                       
                       card(
                           HTML('<h5 style="display: inline-block;">Image</h5>'),
                           
                           textOutput('image_name'),
                           textOutput('image_info'),
                           
                           sliderTextInput('score', HTML('<h6 style="display: inline-block;">Image score</h6>'),
                                           choices = c('unscored', 'rejected', 'poor', 'fair', 'good', 'excellent')),
                           
                           textAreaInput('comment', HTML('<h6 style="display: inline-block;">Comments</h6>'), value = '',                                             #******** set value = db$input
                                         width = '100%', rows = 3, placeholder = 'Optional comment'),
                           actionButton('inset', 'Show insets', width = '110px')
                       ),
                       
                       card(
                           HTML('<h5 style="display: inline-block;">Navigate</h5>'),
                           
                           span(
                               actionButton('first', '<<'),
                               actionButton('previous', '<'),
                               actionButton('next', '>'),
                               actionButton('last', '>>'),
                               
                               hr(),
                               
                               actionButton('exit', 'Exit')
                           ),
                       ),
                )
            )
        )
    )
    
    
    
    # Server -----------------------------
    server <- function(input, output, session) {
        
        # bs_themer()                                                                                       # uncomment to select a new theme
        
        
        observeEvent(input$site, {                                                                          # --- picked a site                                                         
            session$userData$dir <- resolve_dir(the$flightsdir, input$site)
            
            screen <- build_screen_db(input$site)
            session$userData$db <- screen$db
            session$userData$db_name <- screen$db_name
            
            lays <- nrow(session$userData$db)
            scored <- sum(session$userData$db$qualty > 0)
            pct <- round(scored / lays * 100, 0)
            info <- paste0(' - ', scored, ' scored of ', lays, ' (', pct, '%)')
            
            output$site_info <- renderText(paste0(sites$site_name[sites$site == input$site], info))
            
            
            session$userData$index <- 1                   # ***** unless there are no images for site
            output$image_name <- renderText(session$userData$db$name[session$userData$index])
            
            
            footfile <- file.path(resolve_dir(the$shapefilesdir, input$site), 
                                  sites$footprint[sites$site == input$site])
            session$userData$footprint <- st_read(footfile, quiet = TRUE)    
            
            session$userData$tiffs <- grep('.tif$', list.files(session$userData$dir), value = TRUE)
            session$userData$tiffs <- grep('Mica_Ortho', session$userData$tiffs, value = TRUE)
            
            session$userData$full <- rast(file.path(session$userData$dir, session$userData$tiffs[1]))
            bands <- nlyr(session$userData$full)
            coverage <- 82   # ******************************************** pull % coverage from db or calculate and save it
            
            image_info <- paste0(bands, ' band', ifelse(bands > 1, 's', ''), ' | ', coverage, '% coverage')
            output$image_info <- renderText(image_info)
            
            output$inset1 <- NULL
            output$inset2 <- NULL
            output$full <- screen_plot('full', input, output, session = getDefaultReactiveDomain())
            
        })
        
        observeEvent(input$inset, {                                                                         # --- requested inset
            session$userData$inset1 <- center_zoom(session$userData$full, 0.1)
            output$inset1 <- screen_plot('inset1', input, output, session = getDefaultReactiveDomain())
            
            session$userData$inset2 <- center_zoom(session$userData$full, 0.01)
            output$inset2 <- screen_plot('inset2', input, output, session = getDefaultReactiveDomain())
            
        })
        
        
        
        
        
        
        
        observeEvent(input$exit, {
            save_screen_db(session$userData$db, session$userData$db_name)
            message('Screening database saved')
            stopApp()
        })
    }
    
    
    shinyApp(ui = ui, server = server)
}
