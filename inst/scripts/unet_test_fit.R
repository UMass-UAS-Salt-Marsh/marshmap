library(reticulate)

# Source the Python script
source_python("inst/python/train_unet.py")



original_classes <- c(3, 4, 5, 6)  # Maps to 0, 1, 2, 3 internally
site <- 'nor'
model <- 'unet02'
data_dir <- resolve_dir('X:/projects/uas/marshmap/data/<site>/unet', site) 
output_dir <- file.path(data_dir, 'models')


# Call the training function
result <- train_unet(
 #  data_dir = "X:/projects/uas/marshmap/data/rr/unet/unet01",
 #  data_dir = "X:/projects/uas/marshmap/data/nor/unet/unet02",

   site = "nor",
   data_dir = data_dir,
   output_dir = output_dir,
   n_epochs = 50L,
   batch_size = 8L,
   learning_rate = 0.0001,
   original_classes = original_classes  # Pass the mapping
)

# result will be a list: [model_path, final_accuracy]
print(result)
