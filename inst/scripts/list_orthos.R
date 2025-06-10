# a quick-and-dirty to get standards
# 10 Jun 2025

print_oneperline <- function(x)                                            # helper function to print one line per line with nice line numbers
   cat(sprintf(paste0('% ', floor(log10(length(x))) + 3,'s %s\n'), 
               paste0("[", seq_along(x), "]"), x), sep = "")


library(googledrive)
googledrive::drive_auth(token = readRDS('~/.google_auth/google_drive_token.RDS'))

sites <- read_pars_table('sites') 
sitelist <- c('SOR', 'BAR', 'PEG', 'WEL', 'RED', 'OTH', 'ESS', 'NOR', 'WES')


timestamp <- stamp('17 Feb 2025, 3:22 pm', quiet = TRUE)
ts <- timestamp(now(tz = 'America/New_York'))
cat('Summary of orthophotos, ', ts, ', from list_orthos.R\n\n', sep = '')

for(i in 1:length(sitelist)) {
   cat('\n\nSite: ', sitelist[i], '\n', sep = '')
   
   if(sitelist[i] == 'PEG')
      x <- 'UAS Data Collection/Peggotty Beach, Scituate/RFM Processing Inputs/Orthomosaics/'
   else if(sitelist[i] == 'ESS')
      x <- 'UAS Data Collection/Essex Bay/RFM Processing Inputs/Orthomosaic/'
   else
      x <- file.path(the$gather$sourcedir, sites$site_name[i], '/', the$gather$subdirs[[1]])
   
   dir <- get_dir(x, sourcedrive = 'google', log = NULL)$name
   dir <- dir[grep('.tif$', dir)]
   
   cat(length(dir), ' orthophotos\n', sep = '')
   
   print_oneperline(dir)
}
