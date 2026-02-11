# Script to print confusion matrix from U-Net model with test set


original_classes <- c(3, 4, 5, 6)  # Maps to 0, 1, 2, 3 internally
site <- 'nor'
model <- 'unet02'
data_dir <- file.path(resolve_dir('X:/projects/uas/marshmap/data/<site>/unet', site), model) 
output_dir <- file.path(data_dir, 'models')

message('data_dir = ', data_dir)
message('model_dir = ', output_dir)

x <- unet_predict(model_path = output_dir, data_dir, site = site, dataset = 'test',
                   num_classes = 4, in_channels = 8,
                   class_mapping = original_classes)

print(unet_confusion_matrix(x))
