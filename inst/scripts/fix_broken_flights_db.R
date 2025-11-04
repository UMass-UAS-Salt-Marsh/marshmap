# fix broken flights db
# I hope this doesn't happen again, but here it is




db <- build_flights_db(site)                                               # update flights database

for(i in 15:26) {
   print(i)
   if(is.numeric(as.numeric(x[i])))
      x[i] <- as.character(as.POSIXct(as.numeric(x[i])))
}

save_flights_db(db$db, db$db_name)  