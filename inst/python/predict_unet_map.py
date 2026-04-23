"""
Predict U-Net on map patches for wall-to-wall mapping.

Loads patches from numpy, predicts in batches, and saves class probabilities.
Supports both categorical and ordinal regression (CORN) models.
Called from R via reticulate.
"""

import torch
import numpy as np
import json
import os
import segmentation_models_pytorch as smp


def corn_probabilities(logits):
    """Convert CORN ordinal logits to per-class probabilities.

    CORN (Conditional Ordinal Regression with Neural Networks) uses K-1
    conditional logits for K classes. Each sigmoid(logit_k) gives the
    conditional probability P(y > k | y >= k).

    Args:
        logits: (batch, K-1, H, W) tensor of CORN logits

    Returns:
        probs: (batch, K, H, W) tensor of per-class probabilities
    """
    cond_probs = torch.sigmoid(logits)                         # P(y > k | y >= k)
    B, Km1, H, W = cond_probs.shape
    K = Km1 + 1

    # Cumulative: P(y >= k) = product of conditional probs for j < k
    # P(y >= 0) = 1 (always)
    cum_ge = torch.ones(B, K, H, W, device=logits.device)
    for k in range(1, K):
        cum_ge[:, k] = cum_ge[:, k - 1] * cond_probs[:, k - 1]

    # Per-class: P(y = k) = P(y >= k) - P(y >= k+1)
    probs = torch.zeros(B, K, H, W, device=logits.device)
    for k in range(K - 1):
        probs[:, k] = cum_ge[:, k] - cum_ge[:, k + 1]
    probs[:, K - 1] = cum_ge[:, K - 1]                        # last class

    return probs


def predict_unet_map(patches_dir, model_weights, config_path, batch_size=64, requirecuda=True):
    """
    Predict on map patches and save probabilities.

    Handles both categorical (softmax) and ordinal (CORN) models.
    For ensembles, per-class probabilities are averaged across models
    regardless of model type, then argmax is taken.

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

    cuda_available = torch.cuda.is_available()
    print(f'CUDA available: {cuda_available}')
    if requirecuda and not cuda_available:
        raise RuntimeError("CUDA is not available but requirecuda=True. "
                           "Check GPU allocation and driver/module setup.")
    device = torch.device('cuda' if cuda_available else 'cpu')
    print(f'Using device: {device}')

    use_ordinal = config.get('use_ordinal', False)
    num_classes = config['num_classes']

    if use_ordinal:
        print(f'Model mode: ORDINAL REGRESSION (CORN, {num_classes} classes, {num_classes - 1} thresholds)')
    else:
        print(f'Model mode: CATEGORICAL ({num_classes} classes)')

    # Load map metadata
    meta_path = os.path.join(patches_dir, 'map_metadata.json')
    with open(meta_path, 'r') as f:
        map_meta = json.load(f)

    site = map_meta['site'].upper()

    # Load patches
    patches_path = os.path.join(patches_dir, f'{site}_map_patches.npy')
    print(f'Loading patches from {patches_path}...')
    patches = np.load(patches_path)                             # (n_patches, H, W, C)
    n_patches = patches.shape[0]
    print(f'  {n_patches} patches, shape {patches.shape}')

    # Handle single model or ensemble
    if isinstance(model_weights, str):
        model_weights = [model_weights]
    n_models = len(model_weights)
    print(f'Predicting with {n_models} model(s)')

    patch_size = patches.shape[1]

    # Accumulate per-class probabilities across models
    all_probs = np.zeros((n_patches, num_classes, patch_size, patch_size),
                         dtype=np.float32)


    os.makedirs(patches_dir, exist_ok=True)
    progress_path = os.path.join(patches_dir, 'progress.txt')
    progress_file = open(progress_path, 'w')
    
    for m_idx, weights_path in enumerate(model_weights):
        msg = f'Model {m_idx + 1} / {n_models}: {os.path.basename(weights_path)}'
        print(f'\n--- {msg} ---')
        progress_file.write(msg + '\n')
        progress_file.flush()

        # Build model — ordinal uses K-1 output channels
        model_classes = num_classes - 1 if use_ordinal else num_classes
        model = smp.Unet(
            encoder_name=config['encoder_name'],
            encoder_weights=None,                               # weights loaded from file
            in_channels=config['in_channels'],
            classes=model_classes
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

                logits = model(batch_tensor)

                if use_ordinal:
                    probs = corn_probabilities(logits)          # (batch, K, H, W)
                else:
                    probs = torch.softmax(logits, dim=1)        # (batch, K, H, W)

                all_probs[start:end] += probs.cpu().numpy()

                if (end % (batch_size * 10) == 0) or (end == n_patches):
                    print(f'  Processed {end} / {n_patches} patches')

        del model
        torch.cuda.empty_cache()


    del patches
    import gc
    gc.collect()                                            # clean up memory

    # Average across models
    all_probs /= n_models

    # Save probabilities
    probs_path = os.path.join(patches_dir, f'{site}_map_probs.npy')
    print(f'\nSaving probabilities to {probs_path}...')
    np.save(probs_path, all_probs)

    # Also save hard predictions for quick inspection
    predictions = np.argmax(all_probs, axis=1)                 # (n_patches, H, W)
    preds_path = os.path.join(patches_dir, f'{site}_map_preds.npy')
    np.save(preds_path, predictions)

    print(f'Prediction complete: {n_patches} patches, {n_models} model(s)')

    return probs_path
