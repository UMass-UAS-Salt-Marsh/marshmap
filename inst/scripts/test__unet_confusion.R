# Script to print confusion matrix from U-Net model with test set



model <- 'unet04'
set <- 'set1'

site <- 'NOR'
data_dir <- file.path(resolve_dir('/project/pi_bcompton_umass_edu/marsh_mapping/data/<site>/unet', site), model, set) 
output_dir <- file.path(data_dir, set, 'models')
model_file <- file.path(output_dir, resolve_dir('unet_<site>_best.pth', site))


model_file <- "/project/pi_bcompton_umass_edu/marsh_mapping/data/nor/unet/unet04/set1/models/unet_NOR_best.pth"


message('data_dir = ', data_dir)
message('model_dir = ', output_dir)

x <- unet_predict(model_file = model_file, data_dir, site = site, dataset = 'test')

print(unet_confusion_matrix(x))
