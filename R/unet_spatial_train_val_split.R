#' Split transects into train and validation sets
#' 
#' @param transects Original sf transects object
#' @param holdout Holdout set to use (uses bypoly<holdout>, classes 1 and 6)
#' @returns List with train and val transect ids
#' @keywords internal


unet_spatial_train_val_split <- function(transects, holdout) {
   
   
   set <- transects[[paste0('bypoly', sprintf('%02d', holdout))]] %in% c(1, 6)
   validate_ids <- transects$poly[set]
   train_ids <- transects$poly[!set]
   
   message('\n=== TRANSECT SPLIT ===')
   message('Train transects: ', length(train_ids))
   message('Validate transects: ', length(validate_ids))
   
   # Show class distribution by transect assignment
   train_transects <- transects[transects$poly %in% train_ids, ]
   val_transects <- transects[transects$poly %in% validate_ids, ]
   
   message('\nTrain class distribution (by transect):')
   print(table(train_transects$subclass))
   
   message('\nValidate class distribution (by transect):')
   print(table(val_transects$subclass))
   
   return(list(
      train_ids = train_ids,
      validate_ids = validate_ids
   ))
}
