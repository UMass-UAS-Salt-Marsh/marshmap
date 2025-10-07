# assess local importance in ranger with importance = "permutation", local.importance = TRUE
# it's way noisier than importance = 'impurity'
# 
# and draft code to get variable importance for a particular class
# given how noisy importance is with permutation, I'm inclined to make this an option in fit,
# so you'd have to go back and refit with class_importance = TRUE
# 
# 28 Aug 2025



v <- list()

for(i in 137:142) {
   v[[i - 136]] <- varImp(readRDS(file.path(the$modelsdir, paste0('fit_', i, '_extra.RDS')))$model_object)$importance
    #  v[[i - 136]] <- cbind(rownames(t), t)
}

x <- do.call(cbind, v)
names(x) <- c('baseline1', 'baseline2', 'baseline3', 'local1', 'local2', 'local3')
x <- x[order(x$baseline1), ]
plot(1:nrow(x), x$baseline1, pch = 19, cex = 0.75, col = 'red')                      # baseline
points(1:nrow(x), x$baseline2, pch = 19, cex = 0.75, col = 'orange')
points(1:nrow(x), x$baseline3, pch = 19, cex = 0.75, col = 'pink')

points(1:nrow(x), x$local1, pch = 19, cex = 0.75, col = 'green')                      # local
points(1:nrow(x), x$local2, pch = 19, cex = 0.75, col = 'blue')
points(1:nrow(x), x$local3, pch = 19, cex = 0.75, col = 'purple')



x <-readRDS(file.path(the$modelsdir, paste0('fit_', 140, '_extra.RDS')))$model_object
subclass <- as.numeric(sub('^class', '', x$trainingData$.outcome))                            # get classes for training data
v <- data.frame(cbind(subclass, x$finalModel$variable.importance.local))

library(dplyr)

x <- v |> 
   group_by(subclass) |>
   summarise_all(mean) |>
   data.frame()

s <- apply(x[-1], 1, max)
x[-1] <- x[-1] / s * 100
z <- as.data.frame(t(x[-1]))
names(z) <- paste0('class', x$subclass)
z <- round(z, 2)

head(z[order(z[, 'class13'], decreasing = TRUE),]['class13'], 20)

