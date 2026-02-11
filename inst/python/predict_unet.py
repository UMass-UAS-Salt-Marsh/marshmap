"""
Predict with trained U-Net model
Returns pixel-level predictions for test patches
"""

import numpy as np
import torch
import torch.nn as nn
import segmentation_models_pytorch as smp
import os

def predict_unet(model_path, data_dir, site, num_classes=4, in_channels=8, 
                 dataset='test', original_classes=None):
   """
    Load trained model and predict on test/validation data
    
    Args:
        model_path: Path to saved model (.pth file)
        data_dir: Directory containing numpy files
        site: Site name (e.g., 'rr')
        num_classes: Number of classes
        in_channels: Number of input channels
        dataset: Which dataset to predict on ('test' or 'validate')
        original_classes: List mapping internal classes to original (e.g., [3,4,5,6])
    
    Returns:
        Dictionary with:
            - predictions: [N, H, W] array of predicted classes
            - labels: [N, H, W] array of true labels
            - masks: [N, H, W] array of masks (1=labeled, 0=unlabeled)
            - probabilities: [N, num_classes, H, W] array of class probabilities
    """

   if original_classes is None:
      original_classes = list(range(num_classes))
   
   print("="*60)
   print(f"Predicting with U-Net on {dataset} set")
   print("="*60)
   
   # Set device
   device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
   print(f"Using device: {device}")
   
   # Load data
   print(f"\nLoading {dataset} data from {data_dir}...")
   patches = np.load(os.path.join(data_dir, f"{site}_{dataset}_patches.npy"))
   labels = np.load(os.path.join(data_dir, f"{site}_{dataset}_labels.npy"))
   masks = np.load(os.path.join(data_dir, f"{site}_{dataset}_masks.npy"))
   
   print(f"  Patches: {patches.shape}")
   print(f"  Labels: {labels.shape}")
   print(f"  Masks: {masks.shape}")
   
   # Convert to torch tensors
   patches_t = torch.from_numpy(patches).float()
   patches_t = patches_t.permute(0, 3, 1, 2)  # [N, H, W, C] -> [N, C, H, W]
   
   print(f"  Total pixels: {labels.size:,}")
   print(f"  Labeled pixels: {(masks == 1).sum():,}")
   
   # Build model
   print("\nBuilding model architecture...")
   model = smp.Unet(
      encoder_name='resnet34',
      encoder_weights=None,  # Don't load ImageNet weights
      in_channels=in_channels,
      classes=num_classes,
   )
   
   # Load trained weights
   print(f"Loading weights from: {model_path}")
   state_dict = torch.load(model_path, map_location=device)
   
   # Handle DataParallel wrapper if present
   if list(state_dict.keys())[0].startswith('module.'):
      # Remove 'module.' prefix from keys
      state_dict = {k.replace('module.', ''): v for k, v in state_dict.items()}
   
   model.load_state_dict(state_dict)
   model = model.to(device)
   model.eval()
   
   # Predict in batches
   print("\nPredicting...")
   batch_size = 8
   n_batches = int(np.ceil(len(patches_t) / batch_size))
   
   all_predictions = []
   all_probabilities = []
   
   with torch.no_grad():
      for i in range(n_batches):
         start_idx = i * batch_size
         end_idx = min((i + 1) * batch_size, len(patches_t))
   
   batch = patches_t[start_idx:end_idx].to(device)
   outputs = model(batch)  # [B, num_classes, H, W]
   
   # Get probabilities (softmax)
   probs = torch.softmax(outputs, dim=1)  # [B, num_classes, H, W]
   
   # Get predictions (argmax)
   preds = torch.argmax(outputs, dim=1)  # [B, H, W]
   
   all_predictions.append(preds.cpu().numpy())
   all_probabilities.append(probs.cpu().numpy())
   
   if (i + 1) % 10 == 0:
      print(f"  Processed {end_idx}/{len(patches_t)} patches")
   
   predictions = np.concatenate(all_predictions, axis=0)
   probabilities = np.concatenate(all_probabilities, axis=0)
   
   # Compute metrics on labeled pixels only
   labeled_mask = masks == 1
   labeled_preds = predictions[labeled_mask]
   labeled_labels = labels[labeled_mask]
   
   # Overall accuracy
   correct = (labeled_preds == labeled_labels).sum()
   total = labeled_mask.sum()
   overall_acc = correct / total if total > 0 else 0
   
   print(f"\nOverall CCR: {overall_acc:.2%}")
   
   # Per-class accuracy
   print("\nPer-class CCR:")
   for c in range(num_classes):
      class_mask = labeled_labels == c
   if class_mask.sum() > 0:
      class_correct = (labeled_preds[class_mask] == c).sum()
      class_acc = class_correct / class_mask.sum()
      print(f"  Class {int(original_classes[c])}: {class_acc:.2%} ({class_mask.sum():,} pixels)")
   else:
      print(f"  Class {int(original_classes[c])}: N/A (no pixels)")
   
   print("\n" + "="*60)
   
   return {
      'predictions': predictions,
      'labels': labels,
      'masks': masks,
      'probabilities': probabilities,
      'original_classes': original_classes
}
