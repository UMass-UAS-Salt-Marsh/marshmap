#' Relaunches specified fits, purging the old job and fit
#' 
#' temporary, but maybe a good idea
#' 
#' jobids One or more jobids
#' @export


refit <- function(jobids) {
   
   
   x <- info(jobids, 'call', summary = FALSE, table = FALSE)
   
   print(1)
   for(i in x$call)
      eval(parse(text = i))
   
   print(2)
   purge(jobids)
   fitpurge(as.numeric(x$callerid))
}