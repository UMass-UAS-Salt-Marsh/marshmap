#' Create a new database 
#' 
#' Creates a new empty fits database (`fdb`) or maps database (`mdb`). This is a
#' drastic function, intended to be used only when initially creating a database
#' or when an existing database is a hopeless mess. Use with great care--this
#' function will destroy any existing database and backups. **This function is drastic and
#' unrecoverable.**
#' 
#' @param database Name of database (`fdb` or `mdb`)
#' @param really If TRUE, creates database, **destroying existing database**
#' @export 


new_db <- function(database, really = FALSE) {
   
   
   if(!really)
      stop('Database ', database, ' won\'t be created unless you use really = TRUE. This will DESTROY your existing database.')
   
   switch(database,
          'fdb' = {
             the$fdb <- data.frame(
                id = integer(),                       # model id, sequential integers. This is fixed for each model and not reused. Refer to models by id or name. When predicting for a model, result geoTIFF is named either id.tif or name_id.tif. Assigned by fit
                name = character(),                   # model name. This is optional, may be added later, and may be changed. May refer to models by permanent id or by name if present. Predicted grids will always include the model id, as well as the current name if set. passed by fit
                site = character(),                   # site (or sites) model is fit to
                method = character(),                 # modeling approach used (rf = random forest, ab = AdaBoost, perhaps others)
                model = character(),                  # This is user-specified model, using find_orthos
                full_model = character(),             # Complete model specification using original variable names. Written to temp file by do_fit
                hyper = character(),                  # hyperparameters specification. Either full spec or the name of a text file (w/o .txt) with the full spec.
                success = logical(),                  # TRUE if the model ran successfully, FALSE if it failed, or NA if a run hasn't been competed yet
                launched = as.POSIXct(character()),   # date and time launched
                status = character(),                 # final slurmcollie status
                error = character(),                  # TRUE if error
                message = character(),                # error message if any
                cores = integer(),                    # cores requested
                cpu = character(),                    # CPU time
                cpu_pct = character(),                # percent CPU used
                mem_req = double(),                   # memory requested (GB)
                mem_gb = double(),                    # memory used (GB)
                walltime = character(),               # elapsed run time
                vars = integer(),                     # number of variables in model
                cases = integer(),                    # sample size of model
                holdout = integer(),                  # number of holdout cases
                CCR = double(),                       # correct classification rate
                kappa = double(),                     # Kappa
                predicted = character(),              # name of predicted geoTIFF, based on model id and name as it existed when prediction was run. Added by map
                score = double(),                     # subjective scoring field - 1 to 5 stars or something
                comment_launch = character(),         # comment set at launch
                comment_assess = character(),         # comment based on assessment
                comment_map = character()             # comment based on final map
             )  
             
             unlink(file.path(the$dbdir, paste0(database, '*.RDS')))             # delete old database and backups
          },
          
          'mdb' = {
             the$mdb <- data.frame(
             )
          },
          stop('Database must be one of "fdb" or "mdb"')
   )
   save_database(database)
   message('New database ', database, ' created')
   
}