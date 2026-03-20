"""
Predict U-Net on map patches for wall-to-wall mapping.

Loads patches from numpy, predicts in batches, and saves class probabilities.
Called from R via reticulate.
"""

import torch
import numpy as np
import json
import os
import segmentation_models_pytorch as smp


def predict_unet_map(patches_dir, model_weights, config_path, batch_size=64):
    """
    Predict on map patches and save probabilities.
    
    Args:
        patches_dir: Directory with map patches numpy and metadata
        model_weights: Path to .pth weights file (or list of paths for ensemble)
        config_path: Path to model config JSON (from training)
        batch_size: Number of patches per GPU batch
    
    Returns:
        Path to saved probabilities numpy file
    """
    
    # Load model config
    with open(config_path, 'r') as f:
        config = json.load(f)
    
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f'Using device: {device}')
    
    # Load map metadata
    meta_path = os.path.join(patches_dir, 'map_metadata.json')
    with open(meta_path, 'r') as f:
        map_meta = json.load(f)
    
    site = map_meta['site'].upper()
    
    # Load patches
    patches_path = os.path.join(patches_dir, f'{site}_map_patches.npy')
    print(f'Loading patches from {patches_path}...')
    patches = np.load(patches_path)                         # (n_patches, H, W, C)
    n_patches = patches.shape[0]
    print(f'  {n_patches} patches, shape {patches.shape}')
    
    # Handle single model or ensemble
    if isinstance(model_weights, str):
        model_weights = [model_weights]
    n_models = len(model_weights)
    print(f'Predicting with {n_models} model(s)')
    
    num_classes = config['num_classes']
    patch_size = patches.shape[1]
    
    # Accumulate probabilities across models
    all_probs = np.zeros((n_patches, num_classes, patch_size, patch_size), 
                         dtype=np.float32)
    
    for m_idx, weights_path in enumerate(model_weights):
        print(f'\n--- Model {m_idx + 1} / {n_models}: {os.path.basename(weights_path)} ---')
        
        # Build model
        model = smp.Unet(
            encoder_name=config['encoder_name'],
            encoder_weights=None,                           # weights loaded from file
            in_channels=config['in_channels'],
            classes=config['num_classes']
        )
        
        # Load weights
        state_dict = torch.load(weights_path, map_location=device, weights_only=True)
        model.load_state_dict(state_dict)
        model = model.to(device)
        model.eval()
        
        # Predict in batches
        with torch.no_grad():
            for start in range(0, n_patches, batch_size):
                end = min(start + batch_size, n_patches)
                
                # (batch, H, W, C) -> (batch, C, H, W) for PyTorch
                batch = patches[start:end].transpose(0, 3, 1, 2)
                batch_tensor = torch.from_numpy(batch.astype(np.float32)).to(device)
                
                logits = model(batch_tensor)                # (batch, num_classes, H, W)
                probs = torch.softmax(logits, dim=1)
                all_probs[start:end] += probs.cpu().numpy()
                
                if (end % (batch_size * 10) == 0) or (end == n_patches):
                    print(f'  Processed {end} / {n_patches} patches')
        
        del model
        torch.cuda.empty_cache()
    
    # Average across models
    all_probs /= n_models
    
    # Save probabilities
    probs_path = os.path.join(patches_dir, f'{site}_map_probs.npy')
    print(f'\nSaving probabilities to {probs_path}...')
    np.save(probs_path, all_probs)
    
    # Also save hard predictions for quick inspection
    predictions = np.argmax(all_probs, axis=1)              # (n_patches, H, W)
    preds_path = os.path.join(patches_dir, f'{site}_map_preds.npy')
    np.save(preds_path, predictions)
    
    print(f'Prediction complete: {n_patches} patches, {n_models} model(s)')
    
    return probs_path
