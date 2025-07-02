# this extracts regexes, surrounded by braces, and strings, separated by +


library(stringr)

s <- 'those + {[a-z]+} + more + {paren + s} + and so on'


regex <- gsub('^\\{|\\}$', '', str_extract_all(s, '\\{[^\\}]*\\}')[[1]])

strings <- str_trim(str_split(s, '\\{[^\\}]*\\}|(\\+)')[[1]])
strings <- strings[strings != '']
