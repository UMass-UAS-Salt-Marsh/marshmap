# transects_to_circles
# Replace field transects and polys with 1 m radius circles, ready for PI-based subclass reassignment
# 18 Mar 2026



library(sf)

# ── Configuration ─────────────────────────────────────────────────────────────
INPUT   <- "/work/pi_bcompton_umass_edu/marsh_mapping/data/nor/shapefiles/NOR_transects.shp"
OUTPUT  <- "/work/pi_bcompton_umass_edu/marsh_mapping/data/nor/shapefiles/NOR_circles.shp"
RADIUS  <- 1                              # 1 m radius = 2 m diameter
TOL     <- 0.1                            # tolerance (m) for field-measured transects slightly under 2 m wide
INHERIT <- c("year", "subclass", "poly", "reject", "reject_why")

# ── Helpers ───────────────────────────────────────────────────────────────────

rot2d <- function(m, angle) {             # rotate n×2 matrix CCW by angle
   ca <- cos(angle); sa <- sin(angle)
   cbind(ca * m[, 1] - sa * m[, 2],
         sa * m[, 1] + ca * m[, 2])
}

min_bbox <- function(poly) {              # minimum-area rotated bounding box
   xy <- st_coordinates(st_convex_hull(poly))[, 1:2]
   n  <- nrow(xy) - 1
   xy <- xy[seq_len(n), ]
   cx <- mean(xy[, 1]); cy <- mean(xy[, 2])
   cc <- sweep(xy, 2, c(cx, cy))
   best <- list(area = Inf)
   for (i in seq_len(n)) {
      j     <- i %% n + 1
      angle <- atan2(cc[j, 2] - cc[i, 2], cc[j, 1] - cc[i, 1])
      rot   <- rot2d(cc, -angle)
      xr    <- range(rot[, 1]); yr <- range(rot[, 2])
      w <- diff(xr); h <- diff(yr)
      if (h > w) {                          # keep x as long axis
         angle <- angle + pi / 2
         rot   <- rot2d(cc, -angle)
         xr    <- range(rot[, 1]); yr <- range(rot[, 2])
         w <- diff(xr); h <- diff(yr)
      }
      if (w * h < best$area)
         best <- list(area = w * h, angle = angle, cx = cx, cy = cy,
                      xmin = xr[1], xmax = xr[2], ymin = yr[1], ymax = yr[2])
   }
   best
}

# Generate circle centres. Primary method: erode poly by r, place an
# axis-aligned grid inside the eroded region. Fallback for thin strips
# (where erosion yields nothing): place centres along the centreline
# derived from the minimum bounding box.
circle_centres <- function(poly, r) {
   sp  <- 2 * r
   bb  <- min_bbox(poly)
   ang <- bb$angle
   
   eroded     <- tryCatch(st_buffer(poly, -(r - TOL)), error = function(e) NULL)
   use_eroded <- !is.null(eroded) &&
      !st_is_empty(eroded) &&
      as.numeric(st_area(eroded)) > 1e-6
   
   if (use_eroded) {
      exy  <- st_coordinates(eroded)[, 1:2]
      anch <- colMeans(exy)
      erot <- rot2d(sweep(exy, 2, anch), -ang)
      xr   <- range(erot[, 1]); yr <- range(erot[, 2])
      n_x  <- floor(diff(xr) / sp) + 1
      n_y  <- floor(diff(yr) / sp) + 1
      xs   <- mean(xr) + ((seq_len(n_x) - 1) - (n_x - 1) / 2) * sp
      ys   <- mean(yr) + ((seq_len(n_y) - 1) - (n_y - 1) / 2) * sp
      g    <- rot2d(as.matrix(expand.grid(x = xs, y = ys)), ang)
      g[, 1] <- g[, 1] + anch[1]; g[, 2] <- g[, 2] + anch[2]
      pts  <- st_as_sf(data.frame(x = g[, 1], y = g[, 2]),
                       coords = c("x", "y"), crs = st_crs(poly))
      return(pts[st_within(pts, eroded, sparse = FALSE)[, 1], ])
   }
   
   # Fallback: centreline from bounding box
   xs <- seq(bb$xmin + r, bb$xmax - r, by = sp)
   if (!length(xs)) return(NULL)
   p  <- rot2d(cbind(xs, (bb$ymin + bb$ymax) / 2), ang)
   p[, 1] <- p[, 1] + bb$cx; p[, 2] <- p[, 2] + bb$cy
   st_as_sf(data.frame(x = p[, 1], y = p[, 2]),
            coords = c("x", "y"), crs = st_crs(poly))
}

# ── Main ──────────────────────────────────────────────────────────────────────
polys     <- st_read(INPUT)
circ_area <- pi * RADIUS^2
inh       <- intersect(INHERIT, names(polys))
results   <- vector("list", nrow(polys))

for (i in seq_len(nrow(polys))) {
   row   <- polys[i, ]
   area  <- as.numeric(st_area(row))
   attrs <- st_drop_geometry(row)[, inh, drop = FALSE]
   
   # Already a 2-m circle? Pass through unchanged.
   n_verts <- nrow(st_coordinates(st_geometry(row)))
   if (n_verts > 20 && abs(area - circ_area) / circ_area < 0.02) {
      results[[i]] <- row[, inh]
      next
   }
   
   if (area < circ_area * 0.9) next    # too small → drop
   
   cens <- circle_centres(row, RADIUS)
   if (is.null(cens) || nrow(cens) == 0) next
   
   circles <- st_buffer(cens, RADIUS)
   circles <- circles[st_within(circles, st_buffer(row, TOL), sparse = FALSE)[, 1], ]
   if (nrow(circles) == 0) next
   
   for (col in inh) circles[[col]] <- attrs[[col]]
   results[[i]] <- circles
}

out <- do.call(rbind, Filter(Negate(is.null), results))
st_write(out, OUTPUT, delete_layer = TRUE)