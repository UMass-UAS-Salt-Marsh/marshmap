#' Give summary of sample data file
#' 
#' @param site Three letter site code
#' @param datafile Name of `.RDS` data file, excluding the extension
#' @importFrom stringr str_extract
#' @export


sampleinfo <- function(site, datafile = 'data') {
   
   
   f <- file.path(resolve_dir(the$samplesdir, site), paste0(datafile, '.RDS'))
   x <- readRDS(f)
   
   cat('Data file ', f, '\n\n', sep = '')

   cat(format(nrow(x), big.mark = ','), ' cases and ', ncol(x), ' variables\n', sep = '')
   cat('\nSubclass frequencies:\n')
   print(table(x$subclass))

   vars <- names(x)
   vars <- vars[!grepl('subclass', vars)]
   b <- grepl('^_', vars)
   
   cat('\n', sum(b), ' blocks variables\n', sep = '')
   if(sum(b) != 0)
      print(vars[b], quote = FALSE)
   
   orthos <- vars[!b]
   n <- str_extract(orthos, '(.*)(_\\d*$)', group = 1)                  # pull bands from multi-band orthos
   m <- table(n[!is.na(n)])                                             # unique orthos and number of bands in each
   z <- paste0(names(m), paste0(' (', m, ') '))                         # multi-band orthos
   z <- c(z, orthos[is.na(n)])                                          # and single-band orthos
   z <- sort(z)
   
   cat('\n', length(z), ' orthos (', sum(!b), ' bands)\n', sep = '')
   print(z, quote = FALSE)
}
