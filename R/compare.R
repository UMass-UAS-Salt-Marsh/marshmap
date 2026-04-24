#' Compare U-Net training runs
#'
#' Scrapes summary.txt files for the given fit IDs and produces a concise
#' side-by-side comparison of U-Net models. Hyperparameters common to all runs are listed
#' once at the top; those that differ are listed per run.
#'
#' @param fits Vector of fit IDs to compare
#' @param md Logical; if TRUE, emit Markdown with bold formatting on key lines. Default FALSE.
#' @param key Logical; if TRUE, prepend a legend explaining the output format. Default FALSE.
#' @returns Invisible character vector of the output lines
#' @export


compare <- function(fits, md = FALSE, key = FALSE) {
   
   
   insert_stars <- function(x) {
      x <- sub('^(\\s*)(\\S)', '\\1**\\2', x, perl = TRUE)
      sub('(?=\\s*$)', '**', x, perl = TRUE)
   }
   
   
   # ---- Read and parse all summary files ----
   
   load_database('fdb')                                  # Get fit database
   
   runs <- lapply(fits, function(fit) {
      i <- match(fit, the$fdb$id)
      if (is.na(i)) stop('Fit id ', fit, ' not found in fits database')
      
      sum_path <- file.path(resolve_dir(the$unetdir, the$fdb$site[i]),
                            the$fdb$datafile[i], 'summary.txt')
      if (!file.exists(sum_path))
         stop('Summary file not found for fit ', fit, ': ', sum_path)
      
      parse_summary(readLines(sum_path), fit)
   })
   names(runs) <- fits
   
   
   # ---- Build channel descriptions ----
   for (i in seq_along(runs))
      runs[[i]]$channel_desc <- describe_channels(runs[[i]]$images)
   
   
   # ---- Smart hyperparameter display ----
   # Collect all params across runs
   param_names <- unique(unlist(lapply(runs, function(r) names(r$params))))
   
   # Split into common (same across all) and differing
   common_params <- list()
   diff_params <- list()
   
   for (pn in param_names) {
      vals <- sapply(runs, function(r) {
         v <- r$params[[pn]]
         if (is.null(v)) NA_character_ else as.character(v)
      })
      if (length(unique(na.omit(vals))) <= 1 && !any(is.na(vals))) {
         common_params[[pn]] <- vals[1]
      } else {
         diff_params[[pn]] <- vals
      }
   }
   
   
   # ---- Output ----
   lines <- character()
   ln <- function(...) lines <<- c(lines, paste0(...))
   b  <- if (md) function(x) insert_stars(x) else identity   # bold helper

   # Optional key
   if (key) {
      ln(b('Model summary key'))
      ln('')
      if(md) ln('')
      ln(b('fit id   model nickname   model path   site abbreviation   [classes]   field data year'))
      ln('   class set')
      ln('number of x variables:   flight year   flight season - tide stage  (bands), ...')
      ln(paste0('   ', b('CCR = % correct   (range across 5 cross-validations), Kappa')))
      ln('   class   class CCR,   class F1,   n pixels in class   (n polys train / test)   class name')
      ln('   ...')
      ln('')
      if(md) ln('')
   }

   # Common parameters header
   if (length(common_params) > 0) {
      ln('Common parameters: ',
         paste(names(common_params), unlist(common_params), sep = '=', collapse = ', '))
      ln('')
      if(md) ln('')
   }

   # Load classes table for name lookup
   classes_tbl <- tryCatch(read_pars_table('classes'), error = function(e) NULL)

   # Each run
   for (fit in fits) {
      r <- runs[[as.character(fit)]]

      # Look up class names for this run's class column
      class_names <- rep('', length(r$class_ids))
      if (!is.null(classes_tbl)) {
         reclass <- r$params[['reclass']]
         class_col <- if (!is.null(reclass) && reclass != 'NULL' && nzchar(reclass)) reclass else 'subclass'
         name_col  <- paste0(class_col, '_name')
         if (name_col %in% names(classes_tbl)) {
            class_names <- sapply(r$class_ids, function(cls_id) {
               idx <- which(classes_tbl[[class_col]] == as.numeric(cls_id))
               if (length(idx) == 0) return('')
               nm <- trimws(classes_tbl[[name_col]][idx[1]])
               tolower(nm)
            })
         }
      }

      # Header line: fitid model/fitname site [classes] years + differing params
      diff_str <- ''
      if (length(diff_params) > 0) {
         diffs <- sapply(names(diff_params), function(pn) {
            v <- diff_params[[pn]][as.character(fit)]
            if (!is.na(v)) paste0(pn, '=', v) else NULL
         })
         diffs <- unlist(diffs[!sapply(diffs, is.null)])
         if (length(diffs) > 0) diff_str <- paste0(' ', paste(diffs, collapse = ', '))
      }

      ln(b(paste0(fit, ' ', r$model, '/', r$fitname, ' ', r$site, ' ', r$classes_str, ' ',
                  r$train_years, diff_str)))

      # Channel description
      ln(r$channel_desc)

      # Transects if present
      if (!is.null(r$params$transects))
         ln('transects: ', r$params$transects)

      # Overall stats
      ln(b(paste0('\tCCR = ', r$ccr, '% (', r$ccr_range, '), Kappa = ', r$kappa)))

      # Per-class lines: build without class name first, then pad and append
      per_class_lines <- vapply(seq_along(r$class_ids), function(j) {
         paste0('\t', r$class_ids[j], ' ', r$class_ccr[j], '%, F1 = ', r$class_f1[j],
                ', n = ', r$class_npix[j], ' (', r$class_polys[j], ')')
      }, character(1))

      if (any(nzchar(class_names))) {
         max_w <- max(nchar(per_class_lines))
         for (j in seq_along(per_class_lines)) {
            padding <- strrep(' ', max_w - nchar(per_class_lines[j]) + 4)
            ln(per_class_lines[j], padding, class_names[j])
         }
      } else {
         for (j in seq_along(per_class_lines))
            ln(per_class_lines[j])
      }

      ln('')
      if(md) ln('')
   }
   
   out <- paste(lines, collapse = '\n')
   cat(out, '\n')
   invisible(lines)
}


#' Parse a summary.txt file into a structured list
#' @param lines Character vector of lines from summary.txt
#' @param fit Fit ID (for error messages)
#' @returns List with parsed components
#' @keywords internal

parse_summary <- function(lines, fit) {
   
   r <- list()
   
   # Model name: line starting with 'Model: '
   model_line <- grep('^Model:', lines, value = TRUE)
   if (length(model_line) == 0) stop('No Model: line in summary for fit ', fit)
   r$model <- trimws(sub('^Model:', '', model_line[1]))
   
   # Train and result
   train_line <- grep('^Train:', lines, value = TRUE)
   r$train <- if (length(train_line)) trimws(sub('^Train:', '', train_line[1])) else 'unknown'
   
   result_line <- grep('^Result:', lines, value = TRUE)
   if (length(result_line)) {
      r$result_path <- trimws(sub('^Result:', '', result_line[1]))
      r$fitname <- basename(r$result_path)
   } else {
      r$fitname <- 'unknown'
   }
   
   # Site
   site_line <- grep('^\\s+- site:', lines, value = TRUE)
   r$site <- if (length(site_line)) trimws(sub('.*site:\\s*', '', site_line[1])) else 'unknown'
   
   # Classes
   classes_line <- grep('^\\s+- classes:', lines, value = TRUE)
   if (length(classes_line)) {
      r$classes_str <- trimws(sub('.*classes:\\s*', '', classes_line[1]))
      r$class_ids <- as.character(
         as.numeric(strsplit(gsub('[][]', '', r$classes_str), ',')[[1]])
      )
   }
   
   # Train years
   years_line <- grep('^\\s+- train years:', lines, value = TRUE)
   r$train_years <- if (length(years_line)) trimws(sub('.*train years:\\s*', '', years_line[1])) else ''
   
   # Polys
   polys_line <- grep('^\\s+- polys:', lines, value = TRUE)
   r$polys_str <- if (length(polys_line)) trimws(sub('.*polys:\\s*', '', polys_line[1])) else ''
   
   # CCR, range, kappa
   ccr_line <- grep('^\\s+- CCR =', lines, value = TRUE)
   if (length(ccr_line)) {
      # 'CCR = 69.7, range = 56–80%, Kappa = 0.53'
      r$ccr <- regmatches(ccr_line, regexpr('[0-9]+\\.?[0-9]*', ccr_line))
      range_match <- regmatches(ccr_line, regexpr('\\d+[^,]*%', ccr_line))
      r$ccr_range <- if (length(range_match)) range_match else ''
      kappa_match <- regmatches(ccr_line, regexpr('Kappa = [0-9.-]+', ccr_line))
      r$kappa <- if (length(kappa_match)) sub('Kappa = ', '', kappa_match) else ''
   }
   
   # Per-class CCR, F1, pixel counts, and polys — all parsed from per-class lines
   class_ccr_lines <- grep('^\\s+Class\\s+\\d+:', lines, value = TRUE)
   r$class_ccr   <- character()
   r$class_npix  <- character()
   r$class_f1    <- character()
   r$class_polys <- character()
   for (cl in class_ccr_lines) {
      # CCR
      ccr_val <- regmatches(cl, regexpr('[0-9]+\\.[0-9]+%', cl))
      r$class_ccr <- c(r$class_ccr, sub('%', '', ccr_val))

      # n = pixels (new format) or (X pixels) (old format)
      n_match <- regmatches(cl, regexpr('n = [0-9,]+', cl))
      if (length(n_match)) {
         npix <- sub('n = ', '', n_match)
      } else {
         pix_match <- regmatches(cl, regexpr('\\([0-9,]+ pixels\\)', cl))
         npix <- if (length(pix_match)) gsub('[^0-9,]', '', pix_match) else '?'
      }
      r$class_npix <- c(r$class_npix, npix)

      # F1 (new format only; old format didn't include per-class F1)
      f1_match <- regmatches(cl, regexpr('F1 = [0-9.]+', cl))
      f1_val <- if (length(f1_match)) sub('F1 = ', '', f1_match) else '?'
      r$class_f1 <- c(r$class_f1, f1_val)

      # Polys: first (N/M) pair inside parens
      poly_match <- regmatches(cl, regexpr('\\([0-9]+/[0-9]+', cl))
      poly_val <- if (length(poly_match)) sub('\\(', '', poly_match) else '?/?'
      r$class_polys <- c(r$class_polys, poly_val)
   }

   # Fall back to summary F1 line when per-class lines lack it (old summary.txt)
   if (all(r$class_f1 == '?')) {
      f1_line <- grep('^\\s+- F1 for', lines, value = TRUE)
      if (length(f1_line)) {
         f1_vals <- regmatches(f1_line, gregexpr('[0-9]+\\.[0-9]+', f1_line))[[1]]
         r$class_f1 <- f1_vals
      }
   }

   # Fall back to aggregate polys: line when per-class lines lack it (old summary.txt)
   if (length(r$class_polys) == 0 || all(r$class_polys == '?/?')) {
      if (nchar(r$polys_str) > 0) {
         train_match <- regmatches(r$polys_str, regexpr('train: [0-9/]+', r$polys_str))
         test_match  <- regmatches(r$polys_str, regexpr('test: [0-9/]+',  r$polys_str))
         if (length(train_match) && length(test_match)) {
            train_counts <- strsplit(sub('train: ', '', train_match), '/')[[1]]
            test_counts  <- strsplit(sub('test: ',  '', test_match),  '/')[[1]]
            r$class_polys <- paste0(train_counts, '/', test_counts)
         }
      }
      if (length(r$class_polys) == 0)
         r$class_polys <- rep('?/?', length(r$class_ids))
   }

   # Images
   img_start <- grep('^\\s+- images:', lines)
   r$images <- character()
   if (length(img_start)) {
      j <- img_start[1] + 1
      while (j <= length(lines) && grepl('^\\s+- [A-Za-z0-9]', lines[j])) {
         img <- trimws(sub('^\\s+-\\s+', '', lines[j]))
         r$images <- c(r$images, img)
         j <- j + 1
      }
   }
   
   # Parameters (key-value pairs)
   param_lines <- grep('^\\s+- [a-z_]+:', lines, value = TRUE)
   r$params <- list()
   skip_keys <- c('images', 'site', 'classes', 'train years', 'polys', 
                  'CCR', 'F1 for', 'Per-class')
   for (pl in param_lines) {
      kv <- regmatches(pl, regexpr('[a-z_]+:\\s*.*', pl))
      if (length(kv)) {
         parts <- strsplit(kv, ':\\s*', perl = TRUE)[[1]]
         key <- parts[1]
         val <- if (length(parts) > 1) trimws(parts[2]) else ''
         if (!key %in% c('images', 'site', 'classes') && 
             !grepl('train years|polys|CCR|F1 for|Per-class', key))
            r$params[[key]] <- val
      }
   }
   
   r
}


#' Describe channels from image filenames
#' @param images Character vector of image filenames
#' @returns Character string like '26 channels: 2023 summer-mid (mica,DEM,NDVI,NDRE,NDWIg), post-mid (mica,NDVI,NDRE)'
#' @keywords internal

describe_channels <- function(images) {
   
   if (length(images) == 0) return('0 channels')
   
   # Parse each image filename
   parsed <- lapply(images, parse_image_filename)
   df <- do.call(rbind, lapply(parsed, as.data.frame, stringsAsFactors = FALSE))
   
   # Count channels: base ortho = 5 bands, everything else = 1
   n_channels <- sum(ifelse(df$layer_type == 'mica', 5, 1))
   
   # Get seasons from the function
   season_info <- seasons(images)
   df$season <- season_info$season
   df$year <- season_info$year
   
   # Group by year, season, tide
   df$group <- paste(df$year, df$season, df$tide, sep = '_')
   groups <- unique(df$group)
   
   # For each group, list the layer types
   parts <- character()
   for (grp in groups) {
      gdf <- df[df$group == grp, ]
      yr <- gdf$year[1]
      ssn <- gdf$season[1]
      tide <- gdf$tide[1]
      
      layers <- gdf$layer_type
      layer_str <- paste(layers, collapse = ',')
      
      tide_str <- if (!is.na(tide) && nchar(tide) > 0) paste0('-', tolower(tide)) else ''
      parts <- c(parts, paste0(ssn, tide_str, ' (', layer_str, ')'))
   }
   
   # Get unique years
   years <- unique(df$year)
   year_str <- paste(years, collapse = ',')
   
   paste0(n_channels, ' channels: ', year_str, ' ', paste(parts, collapse = ', '))
}


#' Parse an image filename into components
#' @param filename Image filename like '01Sep23_NOR_Mid_Mica_Ortho.tif' or 
#'   '01Sep23_NOR_Mid_Mica_Ortho__NDVI.tif' or '01Sep23_NOR_Mid_Mica_DEM.tif'
#' @returns List with date, site, tide, sensor, layer_type
#' @keywords internal

parse_image_filename <- function(filename) {
   
   # Remove extension
   base <- tools::file_path_sans_ext(filename)
   
   # Check for derived variable (double underscore)
   if (grepl('__', base)) {
      parts <- strsplit(base, '__')[[1]]
      derived <- parts[2]
      base <- parts[1]
      
      # Parse the base ortho name
      fields <- strsplit(base, '_')[[1]]
      
      return(list(
         date = fields[1],
         site = fields[2],
         tide = fields[3],
         sensor = fields[4],
         layer_type = derived
      ))
   }
   
   # Not derived — parse directly
   fields <- strsplit(base, '_')[[1]]
   
   # Check if it's a DEM or LiDAR
   last <- fields[length(fields)]
   if (toupper(last) == 'DEM') {
      return(list(
         date = fields[1],
         site = fields[2],
         tide = fields[3],
         sensor = fields[4],
         layer_type = 'DEM'
      ))
   }
   
   if (grepl('lidar', tolower(last))) {
      return(list(
         date = fields[1],
         site = fields[2],
         tide = fields[3],
         sensor = fields[4],
         layer_type = 'lidar'
      ))
   }
   
   # Base ortho
   return(list(
      date = fields[1],
      site = fields[2],
      tide = fields[3],
      sensor = tolower(fields[4]),
      layer_type = tolower(fields[4])
   ))
}