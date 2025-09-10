#' Create a frequency table of number of cells by subclass from field data
#' 
#' Create a frequency table of number of cells by subclass from field data for one or more
#' sites. Results are written to the reports directory as `sample_freq_<site>.txt`. 
#' 
#' Always runs locally. Takes about a minute per site.
#' 
#' @param sites One or more site names, using 3 letter abbreviation. Use `all` to process all sites. 
#' @param transects Name of transects file; default is `transects`.
#' @export


sample_freq <- function(sites, transects = NULL) {
   
   
   sites <- get_sites(sites)$site
   
   if(is.null(transects))
      transects <- 'transects.tif'
   
   for(site in sites) {
      f <- file.path(resolve_dir(the$fielddir, tolower(site)), transects)            # field transects file
      if(!file.exists(f))
         message(transects, ' not present for site ', site, '\n')
      
      else {
      
         field <- rast(f)                                                           # raster of transects
         
         x <- table(field[!is.na(field)])                                           # get all sampled cells
         z <- data.frame(x)
         names(z) <- c('subclass', 'count')
         z$pct_max <- round(x / max(x) * 100, 2)
         
         message('Site: ', site)
         print(z)

         f <- file.path(the$reportsdir, paste0('sample_freq_', site, '.txt'))
         write.table(z, f, sep = '\t', row.names = FALSE, quote = FALSE)
         message('Results written to ', f, '\n')
      }
   }
}