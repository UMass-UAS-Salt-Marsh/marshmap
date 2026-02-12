# Script to print confusion matrix from U-Net model with test set


site <- 'nor'
model <- 'unet04'
data_dir <- file.path(resolve_dir('X:/projects/uas/marshmap/data/<site>/unet', site), model) 
output_dir <- file.path(data_dir, 'models')
model_file <- file.path(output_dir, resolve_dir('unet_<site>_best.pth', site))

message('data_dir = ', data_dir)
message('model_dir = ', output_dir)

x <- unet_predict(model_file = model_file, data_dir, site = site, dataset = 'test')

print(unet_confusion_matrix(x))
