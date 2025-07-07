#' Find orthoimages that match search names
#' 
#' Processes user-friendly generalized orthoimage search names, such as 
#' `mica, swir | ortho | low | summer | 2020:2022`, returning a list of matching category values
#' from `categories` in `pars.yml`. These descriptions allow selecting multiple orthoimages clearly
#' and simply (e.g., `mica | low` selects all low-tide Mica images). Importantly for cross-site
#' modeling, dates are replaced by seasons.
#' 
#' Categories are separated by `|` (spaces are optional anywhere except within a name). Use commas
#' to separate multiple tags in a category. Pairs of ordinal categories such as seasons and dates
#' may be provided separated by a colon to designate a sequence; e.g., `2019:2022` is the same as
#' `2019, 2020, 2021, 2022`. Tags may include modifiers (for instance, high tide may be modified as
#' `high-spring`). Modified tags are returned as lists of paired `category, modifier strings: 
#' e.g., `mid-out, high-spring` results in `list(c('mid', 'out'), c('high', 'spring'))`.
#'
#' Non-existent tags generally result in an error with an informative message. Note that, for
#' multiple tags, the category is determined by the first tag, so `sprang, summer, fall` will report
#' all three seasons as errors, even though the second two are correct.
# 
#' @param descrip Description string. See details.
#' @returns A named list of all orthophoto attributes designated in the description
#' @export
#' 
#' @examples
#' require(saltmarsh)
#' init()
#' search_names('mid-in, mid-out, high')
#' search_names('mica, swir, p4 | ortho | high-spring | spring:fall | 2019:2022')
#' search_names('mica, swir | ortho, dem | low:high | spring | 2018')
#' search_names('2022 | oth | mid | mica | ortho | mean-w5')
#' search_names('20x22 | other | muddle | micro')     # this throws an error


search_names <- function(descrip) {
   
   
   descrip <- gsub(' ', '', descrip)                                             # remove all spaces
   
   if(is.null(the$category$site))                                                # get categories not present in pars.yml
      the$category$site <- read_pars_table('sites')$site
   if(is.null(the$category$season))
      the$category$season <- read_pars_table('seasons')$season
   the$category$year <- as.character(2015:2050)
   
   
   cats <- strsplit(descrip, '|', fixed = TRUE)[[1]]                             # split groups on vertical bars
   cats <- cats[cats != '']
   
   z <- errs <- list()
   
   for(i in seq_along(cats)) {                                                   # for each category,
      x <- cats[i]
      
      f <- strsplit(x, '[-,:]')[[1]][1]
      cat <- names(which(sapply(the$category, function(a) f %in% a)))            #    here's our category (from the 1st element)
      
      
      if(length(grep(',', x)) > 0)                                               #    if listed elements in category (e.g., mica, swir),
         x <- strsplit(x, ',')[[1]]                                              #       split them out
      else
         if(length(grep(':', x)) > 0) {                                          #    else, if element includes a range,
            x <- strsplit(x <- cats[i], ':')[[1]]
            if(length(cat) == 0) {
               errs[i] <- cats[i]
               next
            }
            s <- match(x, the$category[cat][[1]])
            x <- the$category[cat][[1]][s[1]:s[2]]                               #       pull out the range (even where it doesn't make sense)
         }
      
      if(length(grep('-', x) > 0)) {
         y <- sapply(x, function(a) strsplit(a, '-'))                            #    now pull out modifiers
         names(y) <- NULL                                                        #    get rid of hideous names
         z[cat] <- list(y)
         errs[i] <- list(unlist(y)[!sub('^w[0-9]+', 'w000', unlist(y)) %in% 
                                      sub('^-', '', unlist(the$category[cat]))])
      }
      else {
         z[cat] <- list(x)
         errs[i] <- list(x[!x %in% unlist(the$category[cat])])
      }
   }
   
   if(length(unlist(errs)) > 0)                                                  # if any errors,
      message('Errors in search name: ', paste(unlist(errs), collapse = ' | '))
   
   z
}