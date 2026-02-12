library(reticulate)

# Source the Python script
message('Sourcing Python code & initializing...')
source_python("inst/python/train_unet.py")



#' **encoder_name**. Pre-trained encoder to use. Choices include `resnet10`, `resnet18`, 
#' `resnet34`, `resnet50`, `efficientnet-b0`, and I think others. The lower `restnet` 
#' numbers have fewer parameters, so are likely to result in more stable training.
#'
#' **encoder_weights**. `imagenet` start with weights learned on ImageNet (natural images); 
#' gives faster convergence, but might bias toward RGB patterns. NULL starts with random 
#' initialization, thus learns everything from this dataset; no bias, but slower training. 
#' You can only use `imagenet` with RGB data, so set it to NULL.
#'
#' **weight_decay**. L2 regularization - penalizes large weights to prevent overfitting. 
#' Higher values (1e-3) = stronger regularization. Lower values (1e-5) = weaker. 
#'
#' **batch_size**. How many patches to process together. Larger (16, 32) uses parallelization
#' on GPUs so trains faster, more stable gradients, uses more GPU memory. Smaller (4, 8) gives
#' noisier gradients (good regularization), less memory, better for small datasets. Use 8; if
#' overfitting is a problem, try 4.
#'
#' **gradient_clip_max_norm**. Prevents exploding gradients by capping gradient magnitude. 
#' Range: 0.5 (aggressive clipping) to 5.0 (gentle); start with 1.0.
#'
#' **early_stopping_patience**. Stop early if no improvement for specified number of epochs. 
#' Use NULL to train all epochs. Start with 15 epochs.


# original_classes <- c(3, 4, 5, 6)  # Maps to 0, 1, 2, 3 internally
original_classes <- c(3, 4, 5)  # Maps to 0, 1, 2, 3 internally
site <- 'nor'
model <- 'unet04'
data_dir <- file.path(resolve_dir('X:/projects/uas/marshmap/data/<site>/unet', site), model) 
output_dir <- file.path(data_dir, 'models')


# Call the training function
result <- train_unet(
   site = site,                           # 3-letter site code
   data_dir = data_dir,                   # source data directory with patch data from prep_unet
   output_dir = output_dir,               # result directory for trained model and diagnostic plots
   use_ordinal = TRUE,                    # ---> USE ORDINAL REGRESSION U-NET!!!
   original_classes = original_classes,   # class mapping - our subclasses corresponding to 0:(n-1) patch classes
   encoder_name = 'resnet18',             # pre-trained encoder to use
   encoder_weights = NULL,                # Load pretrained ImageNet weights, only for plain RGB data ('ImageNet') or train from scratch (NULL)
   learning_rate = 0.0001,                # Learning rate for optimizer
   weight_decay = 1e-4,                   # L2 regularization
   n_epochs = 50L,                        # Number of training epochs
   batch_size = 8L,                       #
   early_stopping_patience = 15,          #  *** add
   gradient_clip_max_norm = 1,            # How much to clip gradient?
   num_classes=3L,                        # Number of classes to fit; must = length(original_classes) and match patch data
   in_channels=16L,                        # Number of input channels (8 for multispectral + NDVI + NDRE + DEM)
   plot_curves = TRUE                     # Create diagnostic plot of fit progress in output_dir?
)

# result will be a list: [model_path, final_accuracy]
print(result)
