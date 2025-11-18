# get hyperparameters used in fit

fitid <- 1391
ef <- file.path(the$modelsdir, paste0('fit_', fitid, '_extra.RDS'))
extra <- readRDS(ef)
extra$model_object$results



# Default tuning:
# mtry min.node.size  splitrule  Accuracy     Kappa  AccuracySD     KappaSD
# 1    2             1       gini 0.9664760 0.9626660 0.001724002 0.001930134
# 2    2             1 extratrees 0.9625935 0.9583260 0.002127244 0.002380029
# 3   32             1       gini 0.9799012 0.9776361 0.001622372 0.001808496
# 4   32             1 extratrees 0.9779068 0.9754119 0.001429993 0.001593501
# 5  526             1       gini 0.9716413 0.9684489 0.002783845 0.003100648
# 6  526             1 extratrees 0.9821434 0.9801324 0.001392749 0.001552119
# 
# 3 fits with tuneLength <- 1
# mtry min.node.size splitrule  Accuracy    Kappa AccuracySD    KappaSD
#    5             1      gini 0.8627166 0.813389 0.01345774 0.01849
#    5             1      gini 0.8648573 0.815323 0.01021441 0.01390375
#    5             1      gini 0.8266186 0.7746241 0.009858607 0.01277057
#    5             1      gini 0.7346712 0.5548579 0.01907751 0.03227874