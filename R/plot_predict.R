#' Read a predict grid and plot it nicely
#' @param tiff A predicted geoTIFF
#' @param pal Selected palette
#' @importFrom terra rast plot
#' @importFrom paletteer paletteer_d
#' @keywords internal


plot_predict <- function(tiff = 'C:/Work/etc/saltmarsh/data/oth/predicted/predict_oth_2025-Apr-28_13-54.tif',
                         pal = 'ggsci::category20b_d3') {
   
   
   pal <- paletteer::paletteer_d(pal)
   
   x <- rast(tiff)
   terra::plot(x, col = pal)
   
}