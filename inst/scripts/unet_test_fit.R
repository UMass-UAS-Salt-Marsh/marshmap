library(reticulate)

# Source the Python script
source_python("inst/python/train_unet.py")

# Call the training function
result <- train_unet(
   data_dir = "X:/projects/uas/marshmap/data/rr/unet/unet01",
   site = "rr",
   n_epochs = 100L,
   batch_size = 8L,
   learning_rate = 0.001
)

# result will be a list: [model_path, final_accuracy]
print(result)
