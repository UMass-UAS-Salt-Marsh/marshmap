library(reticulate)

# Source the Python script
source_python("inst/python/train_unet.py")

# Call the training function
result <- train_unet(
   data_dir = "C:/path/to/your/numpy/files",
   site = "site1",
   n_epochs = 10L,  # L forces integer
   batch_size = 8L,
   learning_rate = 0.001
)

# result will be a list: [model_path, final_accuracy]
print(result)