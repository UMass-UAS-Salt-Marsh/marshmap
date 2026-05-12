#' Combine multiple geoTIFF maps into a single integrated map
#'
#' Worker function for `layer()`. Reads a base map and recursively fills
#' specified codes with values from other maps, producing an integrated
#' classification raster. Each fill rule replaces all cells with a given
#' code in its parent map with the corresponding cells from a fill map.
#' Fill rules can nest arbitrarily: a code in a fill map can itself be
#' filled from yet another map.
#' 
#' Produces:
#' 1. The integrated map as `<result>.tif` (LZW-compressed, with color
#'    table and VAT)
#' 2. A YAML sidecar `<result>_layer.yml` documenting the resolved fill
#'    tree, the final class legend (code, name, source map), and a 
#'    timestamp
#'
#' @param name (character) base name of the YAML config in `pars/unet/`.
#'   For example, `'test1'` reads `pars/unet/test1.yml`.
#' @param rep Throwaway argument to make `slurmcollie` happy.
#' @return Invisibly returns the path to the integrated GeoTIFF.
#' @importFrom terra rast values writeRaster ext crs compareGeom
#' @importFrom yaml read_yaml write_yaml
#' @export


do_layer <- function(name, rep = NULL) {
   
   pars_file <- file.path(the$parsdir, 'unet', paste0(name, '.yml'))
   if(!file.exists(pars_file))
      stop('config file not found: ', pars_file)
   
   cfg <- read_yaml(pars_file)
   
   source_dir <- cfg$source
   result_name <- cfg$result
   base_map <- cfg$base
   fill_rules <- cfg$fill                                                      # NULL or list of rules
   allowmissing <- isTRUE(cfg$allowmissing)
   
   if(is.null(source_dir) || is.null(result_name) || is.null(base_map))
      stop('config must specify source, result, and base')
   
   # Resolve all map paths and load base
   base_path <- map_path(source_dir, base_map)
   message('Loading base map: ', base_map)
   base_r <- rast(base_path)
   
   # Track which source map provided each pixel - parallel raster of source IDs.
   # Source IDs are 1-based indices into source_maps, kept in load order.
   source_maps <- base_map                                                     # vector of source map names
   source_id <- base_r * 0L + 1L                                               # all pixels start at base (id 1)
   
   # Recursively apply fill rules
   if(!is.null(fill_rules)) {
      message('Applying fill rules...')
      out <- apply_fills(base_r, fill_rules, source_dir, source_id, 
                         source_maps, allowmissing)
      base_r <- out$raster
      source_id <- out$source_id
      source_maps <- out$source_maps
   }
   
   # Build class lookup for all codes present in the final map
   message('Building class lookup...')
   v <- values(base_r)
   final_codes <- sort(unique(v[!is.na(v)]))
   
   classes_path <- file.path(the$parsdir, 'classes.txt')                       # adjust if your classes.txt lives elsewhere
   class_lookup <- build_class_lookup(final_codes, classes_path, 
                                      allowmissing = allowmissing)
   
   # Write the integrated GeoTIFF
   result_path <- file.path(source_dir, paste0(result_name, '.tif'))
   message('Writing integrated map: ', result_path)
   write_classified_tif(base_r, result_path, class_lookup, overwrite = TRUE)
   
   # Write the sidecar YAML
   sidecar_path <- sub('\\.tif$', '_layer.yml', result_path)
   write_layer_sidecar(sidecar_path, cfg, base_r, source_id, source_maps, 
                       class_lookup)
   
   message('do_layer finished. Result: ', result_path)
   invisible(result_path)
}


# --- internal helpers ---


#' Recursively apply fill rules to a raster
#' 
#' For each rule, loads the fill map, recursively applies any nested fills
#' *to the fill map* (so they're scoped to its territory), then merges the
#' processed fill map into the parent raster wherever the parent has the 
#' rule's code. This scoping prevents a nested fill from accidentally 
#' overwriting cells in the parent that happen to share a code with the
#' fill map.
#'
#' @param r (SpatRaster) the current state of the integrated raster
#' @param rules (list) fill rules at this level - each entry has `code`,
#'   `map`, optionally `fill`
#' @param source_dir (character) directory containing source maps
#' @param source_id_rast (SpatRaster) parallel raster of source IDs
#' @param source_maps (character) vector of source map names, indexed by
#'   the values in `source_id_rast`
#' @param allowmissing (logical) passed to recursion
#' @return List with `raster`, `source_id`, and `source_maps`
#' @keywords internal


apply_fills <- function(r, rules, source_dir, source_id_rast, 
                        source_maps, allowmissing) {
   
   for(rule in rules) {
      code <- as.integer(rule$code)
      fill_map_name <- rule$map
      nested <- rule$fill                                                      # may be NULL
      
      mask <- (r == code)                                                      # cells in parent to replace
      n_match <- sum(values(mask), na.rm = TRUE)
      
      if(n_match == 0) {
         if(!allowmissing)
            stop('Fill code ', code, ' not present in current raster ',
                 '(map: ', fill_map_name, '). This should have been ',
                 'caught by validation.')
         message('  code ', code, ' not present, skipping fill from ', 
                 fill_map_name)
         next
      }
      
      message(sprintf('  filling code %d from %s (%d cells)', 
                      code, fill_map_name, n_match))
      
      fill_path <- map_path(source_dir, fill_map_name)
      fill_r <- rast(fill_path)
      
      if(!compareGeom(r, fill_r, stopOnError = FALSE))
         stop('Geometry mismatch: ', fill_map_name, ' does not align ',
              'with base map. Check extent/resolution/CRS.')
      
      # Register this fill map and build a per-fill-map source_id raster
      source_maps <- c(source_maps, fill_map_name)
      fill_id <- length(source_maps)
      fill_source_id <- fill_r * 0L + fill_id                                  # all cells from this map get this id
      
      # Apply nested fills to the fill map first (and its source_id), 
      # so they're scoped to fill_r's territory before we merge into parent
      if(!is.null(nested)) {
         out <- apply_fills(fill_r, nested, source_dir, fill_source_id, 
                            source_maps, allowmissing)
         fill_r <- out$raster
         fill_source_id <- out$source_id
         source_maps <- out$source_maps
      }
      
      # Merge the (possibly-nested-filled) fill map into the parent at mask
      r <- ifel(mask, fill_r, r)
      source_id_rast <- ifel(mask, fill_source_id, source_id_rast)
   }
   
   list(raster = r, source_id = source_id_rast, source_maps = source_maps)
}


#' Resolve a map name to a full file path
#' 
#' @keywords internal
map_path <- function(source_dir, map_name) {
   p <- file.path(source_dir, paste0(map_name, '.tif'))
   if(!file.exists(p))
      stop('source map not found: ', p)
   p
}


#' Write the sidecar YAML documenting the integration
#' 
#' @keywords internal
write_layer_sidecar <- function(sidecar_path, cfg, final_r, source_id_rast, 
                                source_maps, class_lookup) {
   
   # Determine source map per final-map code by intersecting code with
   # source_id at each pixel. For each code in the final map, find which
   # source maps contributed it (typically one, but possibly more if the
   # same code appears in multiple maps that were stitched together).
   
   final_vals <- values(final_r)
   src_vals <- values(source_id_rast)
   
   ok <- !is.na(final_vals) & !is.na(src_vals)
   final_vals <- final_vals[ok]
   src_vals <- src_vals[ok]
   
   classes_out <- vector('list', nrow(class_lookup))
   for(i in seq_len(nrow(class_lookup))) {
      code <- class_lookup$value[i]
      src_ids <- unique(src_vals[final_vals == code])
      src_names <- source_maps[src_ids]
      classes_out[[i]] <- list(
         code = as.integer(code),
         name = class_lookup$name[i],
         source = if(length(src_names) == 1) src_names else as.list(src_names)
      )
   }
   
   sidecar <- list(
      input = cfg,                                                             # echo full input config
      classes = classes_out,
      timestamp = format(Sys.time(), '%Y-%m-%d %H:%M:%S %Z')
   )
   
   write_yaml(sidecar, sidecar_path)
   message('Sidecar written: ', sidecar_path)
}
