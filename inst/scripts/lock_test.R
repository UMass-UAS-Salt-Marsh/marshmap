# messing around with unlocking
# I'd use
#    on.exit(load_db('mdb'))
# to load a database and get a lock, with a promise to unlock it if something goes wrong before I save it


unlock <- function(x)
   print(paste0('UNLOCKING ', x))


lock_test <- function(x) {
   print(x)
   if(x == 'bye')
      unlock('now')
   else
      NULL
}


caller <- function(x, y, z) {
   print('starting')
   on.exit(lock_test(x))
   print('now do some stuff')
   if(z == 'okay')            # if okay then bad, throw the error without unlocking
      on.exit(NULL)
   if(y == 'bad')             # if bad, throw an error (and lock if not okay)
      stop('big error')
   print('all done')
   on.exit(NULL)
}

