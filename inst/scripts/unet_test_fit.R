library(reticulate)

# Source the Python script
source_python("inst/python/train_unet.py")



original_classes <- c(3, 4, 5, 6)  # Maps to 0, 1, 2, 3 internally
site <- 'nor'
model <- 'unet02'
data_dir <- file.path(resolve_dir('X:/projects/uas/marshmap/data/<site>/unet', site), model) 
output_dir <- file.path(data_dir, 'models')


# Call the training function
result <- train_unet(
   site = site,
   data_dir = data_dir,
   output_dir = output_dir,
   original_classes = original_classes,      # class mapping
   encoder_name = 'resnet18',                # one of 'resnet18', 'resnet34', 'resnet50', 'efficientnet-b0, or others    *** add
   encoder_weights = 'imagenet',             # 'imagenet' or None    *** add
   learning_rate = 0.0001,                   #
   weight_decay = 1e-4,                      # *** need to add this
   n_epochs = 50L,                           #
   batch_size = 8L,                          #
   early_stopping_patience = 10,             #  *** add
   gradient_clip_max_norm = 1,               #  *** add
   plot_curves = True,                       #  *** add
   use_gpu = True,                           #  *** add
   gpu_ids = 0                               #  *** add - dunno what this is
)

# result will be a list: [model_path, final_accuracy]
print(result)
