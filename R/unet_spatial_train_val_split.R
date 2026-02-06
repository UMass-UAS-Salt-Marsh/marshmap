#' Split transects into train and validation sets
#' 
#' @param transects Original sf transects object
#' @param holdout Holdout set to use (uses bypoly<holdout>, classes 1 and 6)
#' @returns List with train and val transect ids
#' @keywords internal


unet_spatial_train_val_split <- function(transects, holdout) {
   
   
   bypoly_col <- paste0('bypoly', sprintf('%02d', holdout))
   
   train_set <- transects[[bypoly_col]] %in% c(3, 4, 5, 8, 9, 10)    # 60% train
   val_set <- transects[[bypoly_col]] %in% c(1, 6)                   # 20% validate
   test_set <- transects[[bypoly_col]] %in% c(2, 7)                  # 20% test
   
   train_ids <- transects$poly[train_set]
   validate_ids <- transects$poly[val_set]
   test_ids <- transects$poly[test_set]
   
   message('\n=== TRANSECT SPLIT (3-way) ===')
   message('Train transects: ', length(train_ids), ' (groups 3,4,5,8,9,10)')
   message('Validate transects: ', length(validate_ids), ' (groups 1,6)')
   message('Test transects: ', length(test_ids), ' (groups 2,7)')
   
   # Show class distribution
   train_transects <- transects[train_set, ]
   val_transects <- transects[val_set, ]
   test_transects <- transects[test_set, ]
   
   message('\nTrain class distribution (by transect):')
   print(table(train_transects$subclass))
   message('\nValidate class distribution (by transect):')
   print(table(val_transects$subclass))
   message('\nTest class distribution (by transect):')
   print(table(test_transects$subclass))
   
   return(list(
      train_ids = train_ids,
      validate_ids = validate_ids,
      test_ids = test_ids
   ))
}
