# Run this as a batch job with 
#    launch('server_test')

server_test <- function(rep = NULL) {
   
   
   
   message('terra version is ', packageVersion('terra'), '; should be 1.8.73 or higher')
   print(.libPaths())            # I want my home to be before container)
}