#' Find orthophotos for a site
#' 
#' Finds orthophotos at a given site from complete file names, portable names,
#' search names, or regular expressions that match file names or portable names.
#' These may be mixed and matched, separated by `+`. This function is primarily
#' used internally, but you may use this to test and refine orthoimage designations.
#' 
#' Note that portable names will be filtered so there is only one result for 
#' each unique portable name. When there are duplicate portable names at a site,
#' filtering picks the portable name with the highest score, breaking ties by 
#' picking the earliest day in the season. Filtering is only applied to exact matches
#' of portable names, not when they're matched by a regex. File names and search names 
#' that give multiple matches are not filtered.
#' 
#' Use `descrip = '{*}'` to match all names.
#' 
#' You may pass more than one site name, in which case all sites will be searched. In
#' this case, the returned portable names will be the only useful result.
#' 
#' @param site Vector of one or more site names
#' @param descrip Character string with one or more of any of the following, 
#'    separated by `+`:
#' \describe{
#'    \item{file name}{a complete file name (`.tif` is optional)}
#'    \item{portable name}{a portable name}
#'    \item{regex}{a regular expression enclosed in `{}`, to be
#'       applied to both file names and portable names. Regular expressions
#'       are case-insensitive.}
#'    \item{search name}{a search string (see `search_names` for details)}
#' }
#' @param minscore Minimum score for orthos. Files with a minimum score of less than
#'    this are excluded from results. Default is 0, but rejected orthos are always 
#'    excluded.
#' @param maxmissing Maximum percent missing for orthos. Files with percent missing greater
#'    than this are excluded.
#' @returns Data frame with
#' \describe{
#'    \item{row}{row numbers in `flights<site>.txt`}
#'    \item{file}{file names}
#'    \item{portable}{portable names}
#' }
#' @importFrom stringr str_extract_all str_split str_trim
#' @export


find_orthos <- function(site, descrip, minscore = 0, maxmissing = 20) {
   
   
   depth <- function(this)                                                             # get depth of a list
      ifelse(is.list(this), 1L + max(sapply(this, depth)), 0L)
   
   
   mods <- function(cat) {                                                             # get name of mods column for category
      m <- data.frame(cats = c('tide', 'derive'),                                      #    pairs of cat, mod column names in db
                      mods = c('tidemod', 'window'))
      m$mods[match(cat, m$cats)]
   }
   
   
   db <- get_flights_db(site[1])                                                       # get the flights database
   
   if(length(site) > 1)                                                                # if multiple sites, get the rest of the flights databases
      for(i in 2:length(site))
         db <- rbind(db, get_flights_db(site[i]))
   
   
   regex <- gsub('^\\{|\\}$', '', str_extract_all(descrip, '\\{[^\\}]*\\}')[[1]])      # extract regexes, in {}
   
   name <- str_trim(str_split(descrip, '\\{[^\\}]*\\}|(\\+)')[[1]])                    # extract names
   name <- name[name != '']
   z <- integer(0)                                                                     # we'll match an unknown number of names
   
   for(n in name) {                                                                    # for each name,
      if(!grepl('.tif$', n, ignore.case = TRUE))                                       #    filenames end in optional .tif
         m <- paste0(n, '.tif')
      else
         m <- n
      
      i <- match(m, db$name)
      if(!is.na(i))                                                                    #    if we matched a file name,
         z <- c(z, i)                                                                  #       got it and done here
      else {                                                                           #    else,
         i <- match(n, db$portable)
         if(!is.na(i))                                                                 #       if we matched a portable name
            z <- c(z, pick(db$portable[i], db))                                        #          pick from among dups and we're done
         else {                                                                        #       else
            a <- search_names(n)                                                       #          treat it as a search name
            b <- rep(length(a) != 0, nrow(db))                                         #          start with a vector of TRUE unless we found nothing in search_names
            for(j in seq_along(a)) {                                                   #          for each search name part,
               c <- rep(FALSE, nrow(db))
               for(k in seq_along(a[[j]])) {                                           #             for each category,
                  if(depth(a[[j]]) < 1)                                                #                if not nested, it's a regular category, like sensor = mica  
                     c <- c | db[, names(a)[j]] == a[[j]][k]                           #                   match category value
                  else {                                                               #                else, nested list, so category-modifier, like tide = high & tidemod = spring
                     t <- db[, names(a)[j]] == a[[j]][[k]][[1]]
                     if(length(a[[j]][[k]]) > 1)                                       #                   if this one has a mod,
                        t <- t & (db[, mods(names(a)[j])] == a[[j]][[k]][[2]])         #                      need both category and modifier values
                     c <- c | t               
                  }
               }
               b <- b & c
            }
            z <- c(z, seq_along(db$name)[b])
         }
      }
   }
   
   
   for(r in regex) {                                                                   # for each regex,
      s <- grepl(r, db$name, ignore.case = TRUE) |                                     #    match either file name or portable name
         grepl(r, db$portable, ignore.case = TRUE)
      z <- c(z, seq_along(db$name)[s])                                                 #    get any matching row numers
   }
   
   z <- unique(z)
   
   z <- z[(db$score[z] >= minscore) & (db$score[z] != 1)]                              # drop orthos with score < minscore and always drop rejected orthos
   z <- z[is.na(db$pct_missing[z]) | (db$pct_missing[z] > maxmissing)]                 # drop orthos with pct_missing > maxmissing
   
   data.frame(row = z, file = db$name[z], portable = db$portable[z])                   # return data frame of rows, file names, and portable names
}