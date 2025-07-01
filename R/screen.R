#' Screen imagery for salt marsh project
#'
#' @import shiny
#' @import bslib
#' @importFrom shinybusy add_busy_spinner
#' @importFrom shinyjs useShinyjs
#' @import shinyWidgets
#' @importFrom terra rast nlyr
#' @export




screen <- function() {
    
    sites <- read_pars_table('sites')
    sites$footprint <- basename(sites$footprint)
    
    score_choices <- c('unscored', 'rejected', 'poor', 'fair', 'good', 'excellent')
    
    
    
    # User interface ---------------------
    ui <- fluidPage(
        
        theme = bs_theme(bootswatch = 'cerulean', version = 5),                                   # version defense. Use version_default() to update
        includeCSS('www/styles.css'),
        useShinyjs(),
        
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
                       
                       titlePanel(HTML('<H3>Imagery screener</H3>')),
                       
                       card(
                           selectInput('site', label = HTML('<h5 style="display: inline-block;">Site</h5>'), 
                                       choices = sites$site, selectize = FALSE),
                           
                           textOutput('site_info')
                       ),
                       
                       card(
                           HTML('<h5 style="display: inline-block;">Navigate</h5>'),
                           
                           textOutput('image_no'),
                           
                           span(
                               materialSwitch(inputId = 'revisit', label = 'Revisit images', value = FALSE, 
                                              status = 'default'),
                               
                               textInput('filter', HTML('<h6 style="display: inline-block;">Image filter</h6>'), value = '',
                                         width = '100%', placeholder = 'regex'),
                               
                               hr(),                               
                               
                               actionButton('first', '<<'),
                               actionButton('previous', '<'),
                               actionButton('next_', '>'),
                               actionButton('last', '>>')
                           ),
                       ),
                       
                       card(
                           HTML('<h5 style="display: inline-block;">Image</h5>'),
                           
                           textOutput('image_name'),
                           textOutput('portable_name'),
                           uiOutput('image_info'),
                           
                           sliderTextInput('score', HTML('<h6 style="display: inline-block;">Image score</h6>'),
                                           choices = score_choices, force_edges = TRUE),
                           
                           textAreaInput('comment', HTML('<h6 style="display: inline-block;">Comments</h6>'), value = '',
                                         width = '100%', rows = 3),
                           actionButton('inset', 'Show zooms', width = '115px')
                       ),
                       
                       card(
                        actionButton('exit', 'Exit', width = '60px')
                       )
                )
            )
        )
    )
    
    
    
    # Server -----------------------------
    server <- function(input, output, session) {
        
        # bs_themer()                                                                                       # uncomment to select a new theme
        
        
        observeEvent(input$site, {                                                                          # --- picked a site   
            save_flights_db(session$userData$db, session$userData$db_name)                                   #    save database for previous site

            session$userData$dir <- resolve_dir(the$flightsdir, input$site)
            screen <- build_flights_db(input$site)
            
            if(is.null(screen)) {
                output$site_info <- renderText(paste0('There is no flights directory for ', 
                                                      sites$site_name[sites$site == input$site]))
                screen_no_site(input, output, session)
            }
            else
            {
                session$userData$db <- screen$db                                                                #    Get the database for this site
                session$userData$db_name <- screen$db_name
                
                lays <- nrow(session$userData$db) - sum(session$userData$db$deleted)                            #    Site info
                scored <- sum(session$userData$db$score > 0)
                pct <- round(scored / lays * 100, 0)
                if(lays == 0)
                    info <- paste0(' has no images')
                else
                    info <- paste0(' - ', scored, ' scored of ', lays, ' (', pct, '%)')
                output$site_info <- renderText(paste0(sites$site_name[sites$site == input$site], info))
                
                
                footfile <- file.path(resolve_dir(the$shapefilesdir, input$site), 
                                      sites$footprint[sites$site == input$site])
                session$userData$footprint <- st_read(footfile, quiet = TRUE)                                   #    get site footprint
                
                screen_filter(input, output, session)                                                           #    initial filtering
                session$userData$index <- 1                                                                     #    start with first image for site
                screen_image(score_choices, input, output, session = getDefaultReactiveDomain())                #    display the first image
            }
        })
        
        
        observeEvent(input$score, {                                                                         # --- image score
            session$userData$db$score[session$userData$sel[session$userData$index]] <- 
                match(input$score, score_choices) - 1
        })
        
        
        observeEvent(input$comment, {                                                                       # --- image comment
            session$userData$db$comment[session$userData$sel[session$userData$index]] <- 
                input$comment
        })
        
        
        observeEvent(input$inset, {                                                                         # --- requested inset
            sensor <- session$userData$db$sensor[session$userData$sel[session$userData$index]]
            bands <- nlyr(session$userData$full)
            
            session$userData$inset1 <- center_zoom(session$userData$full, 0.1)
            output$inset1 <- screen_plot('inset1', sensor, bands, input, output, session = getDefaultReactiveDomain())
            
            session$userData$inset2 <- center_zoom(session$userData$full, 0.01)
            output$inset2 <- screen_plot('inset2', sensor, bands, input, output, session = getDefaultReactiveDomain())
        })
        
        
        observeEvent(input$revisit, {
            screen_filter(input, output, session)                                                           #    refilter
            session$userData$index <- 1                                                                     #    could bother to look for the one we were on
            screen_image(score_choices, input, output, session = getDefaultReactiveDomain())                #    display the first image
        })
        
        
        observeEvent(input$filter, {
            screen_filter(input, output, session)                                                           #    refilter
            session$userData$index <- 1
            screen_image(score_choices, input, output, session = getDefaultReactiveDomain())                #    display the first image
        })
        
        
        observeEvent(input$first, {                                                                         # --- First image
            session$userData$index <- 1
            screen_image(score_choices, input, output, session = getDefaultReactiveDomain())  
        })
        
        
        observeEvent(input$previous, {                                                                      # --- Previous image
            session$userData$index <- max(session$userData$index - 1, 1)
            screen_image(score_choices, input, output, session = getDefaultReactiveDomain())  
        })
        
        
        observeEvent(input$next_, {                                                                         # --- Next image
            session$userData$index <- min(session$userData$index + 1, length(session$userData$sel))
            screen_image(score_choices, input, output, session = getDefaultReactiveDomain())  
        })
        
        
        observeEvent(input$last, {                                                                         # --- Last image
            session$userData$index <- length(session$userData$sel)
            screen_image(score_choices, input, output, session = getDefaultReactiveDomain())  
        })
        
        
        observeEvent(input$exit, {                                                                         # --- Exit
            save_flights_db(session$userData$db, session$userData$db_name)
            message('Flights database saved')
            stopApp()
        })
    }
    
    
    shinyApp(ui = ui, server = server)
}
