"""
Predict with trained U-Net model
Returns pixel-level predictions for test patches
Supports both categorical and ordinal regression models
"""

import numpy as np
import torch
import torch.nn as nn
import segmentation_models_pytorch as smp
import os

# Try to import CORAL for ordinal predictions
try:
    from coral_pytorch.dataset import corn_label_from_logits
    CORAL_AVAILABLE = True
except ImportError:
    CORAL_AVAILABLE = False

def predict_unet(model_file, data_dir, site, dataset='test'):
    """
    Load trained model and predict on test/validation data
    
    Args:
        model_file: Path to saved model (.pth file)
        data_dir: Directory containing numpy files
        site: Site name (e.g., 'rr')
        dataset: Which dataset to predict on ('test' or 'validate')
    
    Returns:
        Dictionary with:
            - predictions: [N, H, W] array of predicted classes
            - labels: [N, H, W] array of true labels
            - masks: [N, H, W] array of masks (1=labeled, 0=unlabeled)
            - probabilities: [N, num_classes, H, W] array of class probabilities (None for ordinal)
            - original_classes: list of original class numbers
            - config: full model configuration
    """
    
    # Load config
    config_path = model_file.replace('_best.pth', '_config.json')
    
    if not os.path.exists(config_path):
        raise ValueError(f"Config file not found: {config_path}\n"
                        f"Model was probably trained before config saving was implemented.")
    
    import json
    with open(config_path, 'r') as f:
        config = json.load(f)
    
    print(f"Loaded model config: {config}")
    
    # Extract params
    encoder_name = config['encoder_name']
    encoder_weights = config['encoder_weights']
    in_channels = config['in_channels']
    num_classes = config['num_classes']
    use_ordinal = config.get('use_ordinal', False)  # Default False for backward compatibility
    original_classes = config.get('original_classes', list(range(num_classes)))
    
    # Validate ordinal mode
    if use_ordinal and not CORAL_AVAILABLE:
        raise ImportError("This model uses ordinal regression but coral_pytorch is not installed.\n"
                         "Install with: pip install coral-pytorch")
    
    print("="*60)
    print(f"Predicting with U-Net on {dataset} set")
    if use_ordinal:
        print("Model mode: ORDINAL REGRESSION")
    else:
        print("Model mode: CATEGORICAL CLASSIFICATION")
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
    
    # Build model - RESPECT ORDINAL MODE
    print("\nBuilding model architecture...")
    
    if use_ordinal:
        # Ordinal: num_classes - 1 outputs (cumulative thresholds)
        model = smp.Unet(
            encoder_name=encoder_name,
            encoder_weights=None,  # Never use pretrained for prediction
            in_channels=in_channels,
            classes=num_classes - 1,  # CORAL convention
        )
        print(f"  Ordinal regression: {num_classes - 1} cumulative thresholds for {num_classes} classes")
    else:
        # Standard: num_classes outputs
        model = smp.Unet(
            encoder_name=encoder_name,
            encoder_weights=None,  # Never use pretrained for prediction
            in_channels=in_channels,
            classes=num_classes,
        )
        print(f"  Categorical classification: {num_classes} classes")
    
    # Load trained weights
    print(f"Loading weights from: {model_file}")
    state_dict = torch.load(model_file, map_location=device)
    
    # Handle DataParallel wrapper if present
    if list(state_dict.keys())[0].startswith('module.'):
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
            outputs = model(batch)
            
            # Get predictions based on mode
            if use_ordinal:
                # CORAL ordinal: convert logits to predicted class
                # outputs: [B, num_classes-1, H, W]
                B, C, H, W = outputs.shape
                
                # Reshape for CORAL function: [B*H*W, C]
                outputs_flat = outputs.permute(0, 2, 3, 1).reshape(-1, C)
                
                # Get ordinal predictions: [B*H*W]
                preds_flat = corn_label_from_logits(outputs_flat)
                
                # Reshape back: [B, H, W]
                preds = preds_flat.reshape(B, H, W)
                
                # Note: Ordinal probabilities are cumulative, not direct class probs
                # For simplicity, we don't compute them here (would need conversion)
                # If needed, sigmoid(outputs) gives cumulative probabilities P(y <= k)
                
            else:
                # Standard categorical
                # outputs: [B, num_classes, H, W]
                probs = torch.softmax(outputs, dim=1)  # [B, num_classes, H, W]
                preds = torch.argmax(outputs, dim=1)  # [B, H, W]
                all_probabilities.append(probs.cpu().detach().numpy())
            
            all_predictions.append(preds.cpu().detach().numpy())
            
            if (i + 1) % 10 == 0:
                print(f"  Processed {end_idx}/{len(patches_t)} patches")
    
    # Concatenate results
    predictions = np.concatenate(all_predictions, axis=0)
    
    if use_ordinal:
        probabilities = None  # Ordinal probabilities not computed
        print("\nNote: Probability maps not generated for ordinal models")
    else:
        probabilities = np.concatenate(all_probabilities, axis=0)
    
    print(f"\nPrediction complete!")
    print(f"  Total labeled pixels: {(masks == 1).sum()}")
    print(f"  Overall CCR: {((predictions[masks == 1] == labels[masks == 1]).sum() / (masks == 1).sum()):.2%}")
    print(f"Final predictions shape: {predictions.shape}")
    if probabilities is not None:
        print(f"Final probabilities shape: {probabilities.shape}")
    
    # Compute metrics on labeled pixels only
    print(f"\nArray shapes:")
    print(f"  predictions: {predictions.shape}")
    print(f"  labels: {labels.shape}")
    print(f"  masks: {masks.shape}")
    
    # Flatten for metrics
    labeled_mask = (masks == 1).flatten()
    labeled_preds = predictions.flatten()[labeled_mask]
    labeled_labels = labels.flatten()[labeled_mask]
    
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
        'probabilities': probabilities,  # None for ordinal models
        'original_classes': original_classes,
        'config': config
    }
