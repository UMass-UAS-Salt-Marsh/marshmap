#' Find orthophotos for a site
#' 
#' Finds orthophotos at a given site from complete file names, portable names,
#' search names, or regular expressions that match file names or portable names.
#' These may be mixed and matched, separated by `+`.
#' 
#' Note that portable names will be filtered so there is only one result for 
#' each unique portable name. When there are duplicate portable names at a site,
#' filtering picks the portable name with the highest score, breaking ties by 
#' picking the earliest day in the season.
#' 
#' @param site Site name
#' @param descrip Character string with one or more of any of the following, 
#'    separated by `+`:
#'    \item{file name}{a complete file name (`.tif` is optional)}
#'    \item{portable name}{a portable name}
#'    \item{regex}{a regular expression enclosed in `{}`, to be
#'       applied to both file names and portable names. Regular expressions
#'       are case-insensitive.}
#'    \item{search name}{a search string (see `search_names` for details)}
#' @returns Data frame with
#'   \item{row}{row numbers in `flights<site>.txt`}
#'   \item{file}{file names}
#'   \item{portable}{portable names}
#' importFrom stringr str_extract_all str_split str_trim
#' @export


find_orthos <- function(site, descrip) {
   
   
   site <- tolower(site)                                                               # get the flights directory for this site
   dir <- resolve_dir(the$flightsdir, site)
   if(!dir.exists(dir))
      stop('There is no flights directory for site ', site)
   db_name <- file.path(dir, paste0('flights_', site, '.txt'))
   if(!file.exists(db_name))
      stop('The flights directory for site ', site, ' hasn\'t been built yet')
   db <- read.table(db_name, sep = '\t', header = TRUE)
   
   
   regex <- gsub('^\\{|\\}$', '', str_extract_all(descrip, '\\{[^\\}]*\\}')[[1]])      # extract regexes, in {}
   
   name <- str_trim(str_split(descrip, '\\{[^\\}]*\\}|(\\+)')[[1]])                    # extract names
   name <- name[name != '']
   z <- integer(0)                                                                     # we'll match an unknown number of names
   
   for(n in name) {                                                                    # for each name,
      if(!grepl('.tif$', n, ignore.case = TRUE))                                       #    filenames end in optional .tif
         m <- paste0(n, '.tif')
      
      i <- match(m, db$name)
      if(!is.na(i))                                                                    #    if we matched a file name,
         z <- c(z, i)                                                                  #       got it and done here
      else {                                                                           #    else,
         i <- match(n, db$portable)
         if(!is.na(i))                                                                 #       if we matched a portable name
            z <- c(z, pick(db$portable[i]))                                            #          pick from among dups and we're done
         else {                                                                        #       else
            a <- search_names(n)                                                       #          treat it as a search name
            k <- rep(TRUE, nrow(db))
            for(j in seq_along(a)) {
               k <- k & db[, names(a)[j]] == a[[j]]               # *** but need to deal with mods too
               z <- c(z, seq_along(db$file)[k])
            }
         }
      }
   }
   
   for(r in regex) {                                                                   # for each regex,
      s <- grepl(r, db$file, ignore.case = TRUE) |                                     #    match either file name or portable name
         grepl(r, db$portable, ignore.case = TRUE)
      z <- c(z, seq_along(db$file)[s])                                                 #    get any matching row numers
   }
   
   
   data.frame(row = z, file = db$file[z], portable = db$portable[z])                   # return data frame of rows, file names, and portable names
}