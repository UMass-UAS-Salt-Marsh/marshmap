#' Build a class lookup table by searching across class-code columns
#'
#' Searches for each given class code across all class-code columns in
#' `classes.txt` (`subclass`, `ICS_V4`, `ICS_V5`, `ICS_V6`) and returns a
#' data frame of `value`, `name`, and `color`. This supports integrated
#' maps that mix levels (e.g., `subclass`-level water codes 21/22 alongside
#' `ICS_V4`-level vegetation codes 102/104).
#' 
#' For each code, all matching `(name, color)` pairs across columns are
#' collected. If a unique pair is found, it's used. If multiple distinct
#' pairs are found, the function errors with the conflicting columns named.
#' If no match is found, the function errors unless `allowmissing = TRUE`,
#' in which case the code is dropped from the lookup with a warning.
#'
#' Rows where the code is 999 or the name is `'xxx'` are treated as 
#' placeholders and ignored during the search.
#' 
#' @param codes (integer) vector of class codes appearing in the map.
#'   Must be in 0-255 (INT1U range).
#' @param classes_path (character) path to `classes.txt` (tab-separated).
#'   Defaults to the path returned by `read_pars_table('classes')` when
#'   called via the standard project workflow; for standalone use, supply
#'   explicitly.
#' @param levels (character) optional vector of column names to restrict
#'   the search to (e.g., `c('subclass', 'ICS_V4')`). If `NULL` (default),
#'   all class-code columns are searched.
#' @param allowmissing (logical) if `FALSE` (default), missing codes throw
#'   an error. If `TRUE`, missing codes generate a warning and are dropped
#'   from the lookup.
#' @return A data frame with columns `value` (integer), `name` (character),
#'   and `color` (character, hex like `'#27408b'`), one row per code, sorted
#'   by `value`.
#' @export


build_class_lookup <- function(codes, classes_path, levels = NULL, 
                               allowmissing = FALSE) {
   
   codes <- sort(unique(as.integer(codes)))                                    # dedupe & sort
   
   if(any(is.na(codes)))
      stop('codes contains NA values')
   
   bad <- codes[codes < 0 | codes > 255]                                       # INT1U range check
   if(length(bad) > 0)
      stop('Codes outside INT1U range (0-255): ', 
           paste(bad, collapse = ', '), 
           '. INT1U rasters cannot encode these values.')
   
   classes <- read.delim(classes_path, stringsAsFactors = FALSE)               # read TSV
   
   # Identify class-code columns (those with a matching _name and _color)
   all_cols <- names(classes)
   code_cols <- all_cols[paste0(all_cols, '_name') %in% all_cols & 
                            paste0(all_cols, '_color') %in% all_cols]
   
   if(!is.null(levels)) {                                                      # restrict to user-specified columns
      missing_cols <- setdiff(levels, code_cols)
      if(length(missing_cols) > 0)
         stop('levels contains unknown column(s): ', 
              paste(missing_cols, collapse = ', '), 
              '. Available: ', paste(code_cols, collapse = ', '))
      code_cols <- levels
   }
   
   # For each code, search every code column and gather (name, color) pairs
   result <- data.frame(value = integer(0), name = character(0), 
                        color = character(0), stringsAsFactors = FALSE)
   missing_codes <- integer(0)
   
   for(code in codes) {
      hits <- character(0)                                                     # 'name|color' strings, deduplicated below
      hit_cols <- character(0)                                                 # which columns provided each hit (for error msg)
      
      for(col in code_cols) {
         name_col <- paste0(col, '_name')
         color_col <- paste0(col, '_color')
         
         vals <- classes[[col]]
         names_ <- classes[[name_col]]
         colors <- classes[[color_col]]
         
         # Skip placeholder rows: code == 999, name == 'xxx', or name blank/NA
         keep <- !is.na(vals) & vals != 999 & 
            !is.na(names_) & names_ != 'xxx' & nzchar(names_)
         
         match_idx <- which(keep & vals == code)
         if(length(match_idx) > 0) {
            for(i in match_idx) {
               key <- paste(names_[i], colors[i], sep = '|')
               hits <- c(hits, key)
               hit_cols <- c(hit_cols, col)
            }
         }
      }
      
      uniq_hits <- unique(hits)
      
      if(length(uniq_hits) == 0) {
         missing_codes <- c(missing_codes, code)
      } else if(length(uniq_hits) > 1) {                                       # ambiguous: same code, different (name, color)
         details <- character(0)
         for(h in uniq_hits) {
            cols_for_h <- unique(hit_cols[hits == h])
            parts <- strsplit(h, '|', fixed = TRUE)[[1]]
            details <- c(details, sprintf('  in %s: name="%s", color="%s"', 
                                          paste(cols_for_h, collapse = ', '), 
                                          parts[1], parts[2]))
         }
         stop('Ambiguous lookup for code ', code, 
              ': multiple distinct (name, color) pairs found:\n', 
              paste(details, collapse = '\n'))
      } else {                                                                 # exactly one
         parts <- strsplit(uniq_hits, '|', fixed = TRUE)[[1]]
         result <- rbind(result, data.frame(value = code, 
                                            name = parts[1], 
                                            color = parts[2], 
                                            stringsAsFactors = FALSE))
      }
   }
   
   if(length(missing_codes) > 0) {
      msg <- paste0('Codes not found in any class column: ', 
                    paste(missing_codes, collapse = ', '))
      if(allowmissing) {
         warning(msg, '. Dropping from lookup (allowmissing = TRUE).')
      } else {
         stop(msg, '. Set allowmissing = TRUE to override.')
      }
   }
   
   result[order(result$value), ]
}
