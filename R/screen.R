#' Screen imagery for salt marsh project
#'
#' Used to screen images for quality, this web app allows users to view and score each image,
#' marking images to send back for repair, and entering comments. Results are saved in the
#' flights database for each site, and are used by `flights_report`. Image scores are used to 
#' help select the image to use when there are duplicated portable names. Minimum scores may
#' be included in search names. Rejected images are never used in fitting.
#' 
#' `screen` builds the flights database for each site when you select it from the `site` 
#' dropdown. An alternative to running `screen` is to call `build_fights_db` for each site
#' whenever new images are added. Scores may be added to a sites database 
#' (`flights/flights_<site>.txt`) by hand if necessary.
#' 
#' When an image file is updated (presumably from downloading a repaired image), the old
#' image is replaced in the database with the new one, thus the score, repair flag, and 
#' comments will be reset. This sets you up for assessing repaired images.
#' 
#' `screen` displays the selected image with a red outline indicating the site footprint. 
#' It includes the following controls:
#'
#' - **Site** select the site. All sites listed in pars/sites.txt are included. The full
#'   site name will be displayed, along with the number of scored images, the total number
#'   of images, and the percent that have been scored.
#' - **Revisit images**. Normally, images that have been scored or flagged for repair are
#'   hidden. Turn this switch on to revisit all images. (After scoring or flagging an image,
#'   it won't be hidden until changing sites or toggling this switch.)
#' - **Image filter** enter a regular expression to filter images on either the file name or
#'   portable name (see `README` for a description of names). When the filter is in effect, only
#'   the selected images will be displayed. Usually, typing a distinct portion of the name 
#'   will suffice, but you can go crazy with regular expressions if you want.
#' - **Navigation buttons** Jump to the first, previous, next, or last image for this site.
#'   It takes a couple of seconds to render high-resolution images.
#' - **Image info** displays the image file name, the portable name, the number of bands, and
#'   key components of the image (type, sensor, season, year, and tide stage).
#' - **Image Score** allows you to score each image for quality. Categories are unscored,
#'   poor, fair, good, very good, and excellent. Scoring should take into account the 
#'   amount of missing data, image quality, and artifacts such as cloud stripes and water
#'   reflections.
#' - **Flag for repair** marks images for repair (for instance, stripes are usually due 
#'   to cloud cover on interleaved transects; image processing software can sometimes
#'   remove these). Images flagged for repair will be hidden unless **Revisit images** is
#'   selected.
#' - **Comments**
#' - **Show zooms** shows a 10x and 100x zoom of the center of the image for up-close 
#'   quality inspection. It takes a moment.
#' - **Exit** saves the flights database for the current site and exits (flights databases
#'   are also saved when switching sites).
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
    
    score_choices <- c('unscored', 'rejected', 'poor', 'fair', 'good', 'very good', 'excellent')
    
    
    
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
                           
                           checkboxInput('repair', 'Flag for repair'),
                           
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
        
        observeEvent(input$repair, {                                                                        # --- flag for repair
            session$userData$db$repair[session$userData$sel[session$userData$index]] <- 
                input$repair
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
