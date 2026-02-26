#' Split transects into train and validation sets
#' 
#' @param transects Original sf transects object
#' @param holdout_col Index of holdout set to use, picks from `bypoly01` to `bypoly05`
#' @param cv Number of cross-validations. Use 1 for a single model, up to 5 for five-fold 
#' @param val Validation polys from `holdout_col`. Use NULL to skip validation, or a vector of 
#'      the validation polys for the first cross-validation (these will be incremented for
#'      subsequent validations). For 20% validation holdout, use `val = c(1, 6)`. This will use
#'      `bypoly01 %in% c(1,6)`` for the first cross-validation, `c(2, 7)` for the second, and so on.
#' @param test Test polys from `holdout_col`, as with `val`.
#' @returns List with train and val transect ids
#' @keywords internal


unet_spatial_train_val_split <- function(transects, holdout_col, cv, val, test) {
   
   
   bypoly_col <- paste0('bypoly', sprintf('%02d', holdout_col))
   
   if(!is.null(val))                                                 # update val and test for cross-validation iteration
      val <- val + cv - 1
   if(!is.null(test))
      test <- test + cv - 1
   
   train <- setdiff(1:10, c(val, test))                              # training values are those that aren't in val or test
   
   train_set <- transects[[bypoly_col]] %in% train                   # training set
   val_set <- transects[[bypoly_col]] %in% val                       # validation set
   test_set <- transects[[bypoly_col]] %in% test                     # test set
   
   train_ids <- transects$poly[train_set]
   validate_ids <- transects$poly[val_set]
   test_ids <- transects$poly[test_set]
   
   message('\n=== TRANSECT SPLIT ===')
   message(paste(paste0(sapply(list(train, val, test), length) * 10, '% ', c('train', 'val', 'test')), collapse = ' / '))
   message('Train transects: ', length(train_ids), ' (groups ', paste(train, collapse = ', '), ')')
   message('Validate transects: ', length(validate_ids), ' (groups ', paste(val, collapse = ', '), ')')
   message('Test transects: ', length(test_ids), ' (groups ', paste(test, collapse = ', '), ')')
   
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
