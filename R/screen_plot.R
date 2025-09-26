#' Display plots for screen
#' 
#' @param extent Which plot to show, one of `full`, `inset1`, or `inset2`
#' @param sensor Sensor name, for disentangling Mica's backwards RGB
#' @param bands Number of bands in image
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @importFrom terra rast plotRGB lines map.pal stretch
#' @importFrom sf st_read
#' @importFrom shiny renderPlot
#' @keywords internal


screen_plot <- function(extent, sensor, bands, input, output, session) {
   
   
   data <- switch(extent,
                  full = session$userData$full,
                  inset1 = session$userData$inset1,
                  inset2 = session$userData$inset2
   )
   
   cachedir <- file.path(session$userData$dir, 'cache')
   if(!dir.exists(cachedir))
      dir.create(cachedir, recursive = TRUE
      )
   cache <- file.path(cachedir, paste0(file_path_sans_ext(session$userData$db$name[session$userData$index]), '_', extent, '.png'))
   
   
   if(length(grep('Mica', sensor)) != 0)                       # deal with crazy backwards RGB in Mica images
      rgb <- c(3, 2, 1)
   else
      rgb <- c(1, 2, 3)
   
   
   bands <- nlyr(data)  # ************************ value of bands passed in is sometimes wrong!!! **********************
   
   
   old <- TRUE
   if(old)
      renderPlot({
         if(bands == 1) {
            a <- Sys.time()
            plot(data, col = map.pal('viridis'), breaks = 10, breakby = 'cases', legend = FALSE, axes = FALSE, mar = 0.5)
            cat('Making & plotting single-band image takes ', Sys.time() - a, ' secs\n', sep = '')
            
            # Bug in terra::.get_breaks (https://github.com/rspatial/terra/blob/2a001f940ea658c730c2135be74d41050a6ad13d/R/plot_helper.R#L165)
            # when using breaks > ~20 for image OTH_Aug_CHM_CSF2012_Thin25cm_TriNN8cm.tif. After breaks <- unique(breaks), they need to reduce
            # n if necessary or you get `Error in if ((breaks[n]%%1) != 0) { : missing value where TRUE/FALSE needed`
         }
         else {
            a <- Sys.time()
            plotRGB(data, rgb[1], rgb[2], rgb[3], stretch = 'lin', mar = 0.5)
            cat('Making & plotting three-band image takes ', Sys.time() - a, ' secs\n', sep = '')
            
            if(extent == 'full')
               lines(session$userData$footprint, lwd = 3, col = 'red')
         }
      })
   else {
         a <- Sys.time()
         png(cache)
         if(bands == 1)
            plot(data, col = map.pal('viridis'), breaks = 10, breakby = 'cases', legend = FALSE, axes = FALSE, mar = 0.5)
         else
            plotRGB(data, rgb[1], rgb[2], rgb[3], stretch = 'lin', mar = 0.5)
         if(extent == 'full')
            lines(session$userData$footprint, lwd = 3, col = 'red')
         dev.off()
         cat('Making image takes ', Sys.time() - a, ' secs\n', sep = '')
      
      a <- Sys.time()
      z <- renderImage({
         list(src = cache,
              contentType = 'image/png',
              width = 800,
              height = 800)
      }, 
      deleteFile = FALSE)
   }
   cat('Rendering image takes ', Sys.time() - a, ' secs\n', sep = '')
   z
}
