




# Helper: Calculate NDVI
unet_calc_ndvi <- function(nir, red) {
   (nir - red) / (nir + red + 1e-8)  # epsilon to avoid division by zero
}

# Helper: Calculate NDRE
unet_calc_ndre <- function(nir, red_edge) {
   (nir - red_edge) / (nir + red_edge + 1e-8)
}

# Helper: Normalize raster to 0-1
unet_normalize_band <- function(r, method = "percentile", lower = 0.02, upper = 0.98) {
   if (method == "percentile") {
      vals <- values(r, na.rm = TRUE)
      q_lower <- quantile(vals, lower, na.rm = TRUE)
      q_upper <- quantile(vals, upper, na.rm = TRUE)
      r_norm <- (r - q_lower) / (q_upper - q_lower)
   } else if (method == "minmax") {
      r_norm <- (r - global(r, "min", na.rm = TRUE)[[1]]) / 
         (global(r, "max", na.rm = TRUE)[[1]] - global(r, "min", na.rm = TRUE)[[1]])
   }
   clamp(r_norm, lower = 0, upper = 1, values = TRUE)
}

# Helper: Standardize raster (mean=0, sd=1)
unet_normalize_band <- function(r) {
   r_mean <- global(r, "mean", na.rm = TRUE)[[1]]
   r_sd <- global(r, "sd", na.rm = TRUE)[[1]]
   (r - r_mean) / (r_sd + 1e-8)
}
