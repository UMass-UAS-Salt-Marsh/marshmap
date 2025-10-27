# Run this as a batch job with 
#    launch('server_test')
#    
library(utils)

server_test <- function(rep = NULL) {
   
   
   
   message('terra version is ', packageVersion('terra'), '; should be 1.8.73 or higher')
   print(.libPaths())            # I want my home to be before container)
   
   # x <- .libPaths()
   # h <- grep('/home/', x)
   # .libPaths(x[c(h, seq_along(x)[-h])])
   # 
   # message('Rearranged...')
   # message('terra version is ', packageVersion('terra'), '; should be 1.8.73 or higher')
   # print(.libPaths())
   
}