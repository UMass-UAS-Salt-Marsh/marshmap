#' Create cached images of orthophotos for display in `screen`
#' 
#' @param data raster of ortho image
#' @param cdir cache directory 
#' @param file File name to write cache to
#' @param rgb RGB bands, in order (reversed for Mica)
#' @param extent Extent of image; one of `full`, `inset1`, or `inset2`
#' @param footprint footprint shapefile object
#' @param pixels Maximum resolution in pixels
#' @keywords internal


flights_image <- function(data, cdir, file, rgb, extent, footprint, pixels = 1200) {
   
   
   message(file, '_', extent)
   
   cache <- file.path(cdir, paste0(file_path_sans_ext(file), '_', extent, '.png'))
   
   
   if(extent == 'full') {                                      # figure out the extent
      s <- c(ncol(data), nrow(data))
      size <- s / max(s) * pixels
   }
   else
      size <- pixels / rep(2, 2)

   
   png(cache, width = size[1], height = size[2])               # open up .png output
   
   
   if(nlyr(data) == 1)
      plot(data, col = map.pal('viridis'), breaks = 10, 
           breakby = 'cases', legend = FALSE, axes = FALSE, 
           mar = 0.5)                                          # single band images
   else
      plotRGB(data, rgb[1], rgb[2], rgb[3], stretch = 'lin', 
              mar = 0.5)                                       # RGBs
   
   if(extent == 'full')
      lines(footprint, lwd = 3, col = 'red')                   # and the boundary
   
   dev.off()
}