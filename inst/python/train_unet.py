"""
Train U-Net for salt marsh gradient classification
Uses masked loss to handle sparse transect labels
Supports ordinal regression for ordered classes
"""

# Part 1: Imports and setup

import sys
import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
import random
import os
from pathlib import Path

# Force line-buffered stdout so epoch progress appears in real time
# (important when called via reticulate or batch jobs)
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(line_buffering=True)

# Try to import CORAL for ordinal regression
try:
    from coral_pytorch.dataset import corn_label_from_logits
    from coral_pytorch.losses import corn_loss
    CORAL_AVAILABLE = True
except ImportError:
    CORAL_AVAILABLE = False
    print("NOTE: coral_pytorch not available. Install with: pip install coral-pytorch")
    print("      Ordinal regression will not be available.")

print(f"PyTorch version: {torch.__version__}")


# Part 2: Custom dataset class

class MaskedPatchDataset(Dataset):
    """
    Dataset for loading patches with masks for sparse labels
    
    Handles:
    - Multi-band input patches (8+ channels)
    - Class labels
    - Masks (1 = labeled, 0 = unlabeled)
    - Ignore value 255 for unlabeled pixels
    - Augmentation (rotations and flips)
    """
    
    def __init__(self, patches, labels, masks, augment=True):
        """
        Args:
            patches: numpy array [N, H, W, C] - N patches, H×W size, C channels
            labels: numpy array [N, H, W] - class labels (0-n or 255)
            masks: numpy array [N, H, W] - binary masks (1=labeled, 0=unlabeled)
        """
        self.patches = torch.from_numpy(patches).float()
        self.labels = torch.from_numpy(labels).long()
        self.masks = torch.from_numpy(masks).float()
        
        # PyTorch expects [N, C, H, W] not [N, H, W, C]
        self.patches = self.patches.permute(0, 3, 1, 2)
        self.augment = augment
        
        print(f"Dataset created:")
        print(f"  Patches shape: {self.patches.shape}")
        print(f"  Labels shape: {self.labels.shape}")
        print(f"  Masks shape: {self.masks.shape}")
        
    def __len__(self):
        return len(self.patches)
    
    def __getitem__(self, idx):
        """Return one patch, label, and mask, randomly rotated and flipped"""
        patch = self.patches[idx]
        label = self.labels[idx]
        mask = self.masks[idx]
        
        if self.augment:
            # Random rotation (0, 90, 180, 270)
            if random.random() > 0.5:
                k = random.randint(0, 3)
                patch = torch.rot90(patch, k, dims=[1, 2])
                label = torch.rot90(label.unsqueeze(0), k, dims=[1, 2]).squeeze(0)
                mask = torch.rot90(mask.unsqueeze(0), k, dims=[1, 2]).squeeze(0)
            
            # Random horizontal flip
            if random.random() > 0.5:
                patch = torch.flip(patch, dims=[2])
                label = torch.flip(label, dims=[1])
                mask = torch.flip(mask, dims=[1])
            
            # Random vertical flip
            if random.random() > 0.5:
                patch = torch.flip(patch, dims=[1])
                label = torch.flip(label, dims=[0])
                mask = torch.flip(mask, dims=[0])
        
        return patch, label, mask


# Part 3: Masked loss function (for categorical mode)

class MaskedCrossEntropyLoss(nn.Module):
    """
    Cross-entropy loss that only computes loss on labeled pixels
    Ignores pixels where mask = 0
    """
    
    def __init__(self, weight=None, ignore_index=255):
        super().__init__()
        self.ignore_index = ignore_index
        self.criterion = nn.CrossEntropyLoss(weight=weight, ignore_index=ignore_index, reduction='mean')
        
    def forward(self, pred, target, mask):
        """
        Args:
            pred: [B, C, H, W] - predicted logits (before softmax)
            target: [B, H, W] - ground truth labels
            mask: [B, H, W] - binary mask
        
        Returns:
            loss: scalar tensor
        """
        target_masked = target.clone()
        target_masked[mask == 0] = self.ignore_index
        loss = self.criterion(pred, target_masked)
        return loss


# Part 4: Training function

def train_one_epoch(model, dataloader, criterion, optimizer, device, config):
    """
    Train for one epoch
    
    Args:
        config: dict with 'use_ordinal', 'num_classes', 'ignore_index', 'gradient_clip_max_norm'
    """
    model.train()
    running_loss = 0.0
    nan_count = 0
    
    use_ordinal = config['use_ordinal']
    num_classes = config['num_classes']
    ignore_index = config['ignore_index']
    max_norm = config['gradient_clip_max_norm']
    
    for batch_idx, (patches, labels, masks) in enumerate(dataloader):
        patches = patches.to(device)
        labels = labels.to(device)
        masks = masks.to(device)
        
        # Skip batches with no labeled pixels
        if masks.sum() == 0:
            nan_count += 1
            continue
        
        # Check for NaN in batch
        if torch.isnan(patches).any() or torch.isnan(labels.float()).any():
            print(f"  WARNING: NaN in input batch {batch_idx}")
            nan_count += 1
            continue
        
        optimizer.zero_grad()
        outputs = model(patches)
        
        # Check outputs
        if torch.isnan(outputs).any() or torch.isinf(outputs).any():
            print(f"  WARNING: NaN/Inf in outputs at batch {batch_idx}")
            nan_count += 1
            continue
        
        # Compute loss based on mode
        if use_ordinal:
            # CORAL ordinal loss
            labels_masked = labels.clone()
            labels_masked[masks == 0] = ignore_index
            
            valid_mask = labels_masked != ignore_index
            
            if valid_mask.sum() == 0:
                nan_count += 1
                continue
            
            # Flatten spatial dimensions for CORAL
            # outputs: [B, num_classes-1, H, W] -> [B*H*W, num_classes-1]
            B, C, H, W = outputs.shape
            outputs_flat = outputs.permute(0, 2, 3, 1).reshape(-1, C)
            labels_flat = labels_masked.reshape(-1)
            valid_mask_flat = valid_mask.reshape(-1)
            
            # Filter to valid pixels only
            outputs_valid = outputs_flat[valid_mask_flat]
            labels_valid = labels_flat[valid_mask_flat]
            
            # Compute CORAL loss
            loss = corn_loss(outputs_valid, labels_valid, num_classes=num_classes)
            
        else:
            # Standard categorical cross-entropy
            loss = criterion(outputs, labels, masks)
        
        # Check loss
        if torch.isnan(loss) or torch.isinf(loss):
            print(f"  WARNING: NaN/Inf loss at batch {batch_idx}")
            nan_count += 1
            continue
        
        loss.backward()
        grad_norm = torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=max_norm)
        optimizer.step()
        
        running_loss += loss.item()
    
    epoch_loss = running_loss / (len(dataloader) - nan_count) if (len(dataloader) - nan_count) > 0 else float('nan')
    
    if nan_count > 0:
        print(f"  → {nan_count} batches skipped")
    
    return epoch_loss


# Part 5: Validation function

def validate(model, dataloader, criterion, device, config):
    """
    Validate model and compute metrics
    
    Args:
        config: dict with 'use_ordinal', 'num_classes', 'ignore_index'
    """
    model.eval()
    running_loss = 0.0
    correct = 0
    total = 0
    nan_count = 0
    
    use_ordinal = config['use_ordinal']
    num_classes = config['num_classes']
    ignore_index = config['ignore_index']
    
    class_correct = [0] * num_classes
    class_total = [0] * num_classes
    
    with torch.no_grad():
        for patches, labels, masks in dataloader:
            patches = patches.to(device)
            labels = labels.to(device)
            masks = masks.to(device)
            
            # Skip empty batches
            if masks.sum() == 0:
                nan_count += 1
                continue
            
            outputs = model(patches)
            
            # Get predictions based on mode
            if use_ordinal:
                # CORAL: convert logits to predicted class
                # outputs: [B, num_classes-1, H, W]
                B, C, H, W = outputs.shape
                outputs_flat = outputs.permute(0, 2, 3, 1).reshape(-1, C)
                predicted_flat = corn_label_from_logits(outputs_flat)
                predicted = predicted_flat.reshape(B, H, W)
                
                # Compute loss (optional, for tracking)
                labels_masked = labels.clone()
                labels_masked[masks == 0] = ignore_index
                valid_mask = (labels_masked != ignore_index).reshape(-1)
                
                if valid_mask.sum() > 0:
                    outputs_valid = outputs_flat[valid_mask]
                    labels_valid = labels_masked.reshape(-1)[valid_mask]
                    loss = corn_loss(outputs_valid, labels_valid, num_classes=num_classes)
                    
                    if not (torch.isnan(loss) or torch.isinf(loss)):
                        running_loss += loss.item()
                    else:
                        nan_count += 1
                else:
                    nan_count += 1
                    
            else:
                # Standard: argmax
                _, predicted = torch.max(outputs, 1)
                loss = criterion(outputs, labels, masks)
                
                if not (torch.isnan(loss) or torch.isinf(loss)):
                    running_loss += loss.item()
                else:
                    nan_count += 1
            
            # Compute accuracy (same for both modes)
            mask_bool = masks.bool()
            correct += (predicted[mask_bool] == labels[mask_bool]).sum().item()
            total += mask_bool.sum().item()
            
            # Per-class accuracy
            for c in range(num_classes):
                class_mask = (labels == c) & mask_bool
                if class_mask.sum() > 0:
                    class_correct[c] += (predicted[class_mask] == c).sum().item()
                    class_total[c] += class_mask.sum().item()
    
    epoch_loss = running_loss / (len(dataloader) - nan_count) if (len(dataloader) - nan_count) > 0 else float('nan')
    overall_acc = correct / total if total > 0 else 0
    
    class_acc = []
    for c in range(num_classes):
        if class_total[c] > 0:
            class_acc.append(class_correct[c] / class_total[c])
        else:
            class_acc.append(0.0)
    
    return epoch_loss, overall_acc, class_acc


# Part 6: Main training loop

def train_unet(site, data_dir, output_dir="models", original_classes=None,
    encoder_name="resnet18", encoder_weights=None, learning_rate=0.0001,
    weight_decay=1e-4, n_epochs=50, batch_size=8,
    gradient_clip_max_norm=1.0, num_classes=4, in_channels=None,
    use_ordinal=False, test_interval=5):
    """
    Main training function
    
    Args:
        site: Site's 3-letter code (e.g., "nor")
        data_dir: Directory containing numpy files
        output_dir: Where to save trained model and diagnostic plots
        original_classes: List mapping internal indices to original class numbers
        encoder_name: Pre-trained encoder to use   
        encoder_weights: 'imagenet' or None
        learning_rate: Learning rate for optimizer
        weight_decay: L2 regularization strength
        n_epochs: Number of training epochs
        batch_size: Batch size for training
        gradient_clip_max_norm: Gradient clipping threshold
        num_classes: Number of classes to fit
        in_channels: Number of input channels
        plot_curves: Create diagnostic plots?
        use_ordinal: Use ordinal regression for ordered classes (requires coral_pytorch)
    """
    
    # Read in_channels from metadata JSON if not supplied
    import json
    if in_channels is None:
        metadata_path = os.path.join(data_dir, f"{site}_metadata.json")
        with open(metadata_path) as f:
            metadata = json.load(f)
        in_channels = metadata['in_channels']
        print(f"in_channels read from metadata: {in_channels}")

    # Set up class mapping
    if original_classes is not None:
        original_classes = [int(x) for x in original_classes]
    else:
        original_classes = list(range(num_classes))

    
    # Validate ordinal mode
    if use_ordinal:
        if not CORAL_AVAILABLE:
            raise ImportError("Ordinal regression requires coral_pytorch. "
                            "Install with: pip install coral-pytorch")
        
        # Check that classes are sequential
        if original_classes is not None:
            sorted_classes = sorted(original_classes)
            expected = list(range(sorted_classes[0], sorted_classes[-1] + 1))
            if sorted_classes != expected:
                raise ValueError(f"Ordinal regression requires sequential classes. "
                               f"Got: {original_classes}, expected: {expected}")
        
        print("\n" + "="*60)
        print("*** ORDINAL REGRESSION MODE ***")
        print("Adjacent class errors penalized less than distant errors")
        print("="*60)
    
        
    class_names = {i: f"Class {orig}" for i, orig in enumerate(original_classes)}
    
    print("="*60)
    print(f"Training U-Net for {site}")
    print(f"Class mapping: {class_names}")
    print("="*60)
    
    # Set random seeds for reproducibility
    torch.manual_seed(42)
    np.random.seed(42)

    # Set device
    print(f"CUDA available: {torch.cuda.is_available()}")
    if torch.cuda.is_available():
        print(f"Number of GPUs: {torch.cuda.device_count()}")
        for i in range(torch.cuda.device_count()):
            print(f"  GPU {i}: {torch.cuda.get_device_name(i)}")
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"Using device: {device}")
    
    # Load data
    print("\nLoading training data...")
    train_patches = np.load(os.path.join(data_dir, f"{site}_train_patches.npy"))
    train_labels = np.load(os.path.join(data_dir, f"{site}_train_labels.npy"))
    train_masks = np.load(os.path.join(data_dir, f"{site}_train_masks.npy"))
    
    print(f"Train patches - any Inf: {np.isinf(train_patches).any()}")
    print(f"Train patches - any NaN: {np.isnan(train_patches).any()}")
    
    print("Loading validation data...")
    validate_patches = np.load(os.path.join(data_dir, f"{site}_validate_patches.npy"))
    validate_labels = np.load(os.path.join(data_dir, f"{site}_validate_labels.npy"))
    validate_masks = np.load(os.path.join(data_dir, f"{site}_validate_masks.npy"))

    print("Loading test data...")
    test_patches = np.load(os.path.join(data_dir, f"{site}_test_patches.npy"))
    test_labels = np.load(os.path.join(data_dir, f"{site}_test_labels.npy"))
    test_masks = np.load(os.path.join(data_dir, f"{site}_test_masks.npy"))
    
    # Check input data 
    print("\nInput data ranges:")
    for c in range(train_patches.shape[3]):
        c_data = train_patches[:, :, :, c]
        print(f"  Channel {c}: min={c_data.min():.4f}, max={c_data.max():.4f}, "
              f"mean={c_data.mean():.4f}, std={c_data.std():.4f}")
    
    print(f"\nNaN in patches: {np.isnan(train_patches).any()}")
    print(f"Inf in patches: {np.isinf(train_patches).any()}")
    print(f"NaN in labels: {np.isnan(train_labels).any()}")
    
    unique_labels = np.unique(train_labels)
    print(f"\nUnique label values: {unique_labels}")
    
    actual_classes = len(np.unique(train_labels[train_labels != 255]))
    assert actual_classes == num_classes, f"Found {actual_classes} classes but expected {num_classes}"
    
    # Calculate class weights (not used in ordinal mode)
    print("\nCalculating class weights...")
    class_pixel_counts = np.zeros(num_classes)
    
    for c in range(num_classes):
        count = ((train_labels == c) & (train_masks == 1)).sum()
        class_pixel_counts[c] = float(count)
    
    print(f"\nClass pixel counts:")
    for i in range(num_classes):
        print(f"  Class {int(original_classes[i])} (internal {i}): {class_pixel_counts[i]:.0f} pixels")
    
    if np.any(class_pixel_counts == 0):
        zero_classes = [int(original_classes[i]) for i in range(num_classes) if class_pixel_counts[i] == 0]
        print(f"\nWARNING: Classes {zero_classes} have ZERO training pixels!")
    
    class_weights = 1.0 / (class_pixel_counts + 1e-6)
    class_weights = class_weights / class_weights.sum() * num_classes
    
    if use_ordinal:
        print(f"\nOrdinal mode: class weights NOT used")
    else:
        print(f"\nClass weights: {class_weights}")
    
    # Create datasets
    print("\nCreating datasets...")
    train_dataset = MaskedPatchDataset(train_patches, train_labels, train_masks)
    validate_dataset = MaskedPatchDataset(validate_patches, validate_labels, validate_masks)
    test_dataset = MaskedPatchDataset(test_patches, test_labels, test_masks, augment=False)

    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    validate_loader = DataLoader(validate_dataset, batch_size=batch_size, shuffle=False)
    test_loader = DataLoader(test_dataset, batch_size=batch_size, shuffle=False)

    print(f"\nTrain batches: {len(train_loader)}")
    print(f"Val batches: {len(validate_loader)}")
    print(f"Test batches: {len(test_loader)}")
    
    # # Check encoder weights compatibility
    # if in_channels != 3 and encoder_weights == 'imagenet':
    #     print(f"WARNING: Cannot use ImageNet weights with {in_channels} channels.")
    #     print(f"Setting encoder_weights=None (training from scratch)")
    #     encoder_weights = None
    
    print(f"Encoder: {encoder_name}")
    print(f"Encoder weights: {encoder_weights}")
    
    # Create model
    print("\nBuilding U-Net model...")
    import segmentation_models_pytorch as smp

    if use_ordinal:
        # Ordinal: num_classes - 1 outputs (cumulative thresholds)
        model = smp.Unet(
           encoder_name=encoder_name,
           encoder_weights=encoder_weights,
           in_channels=in_channels,
           classes=num_classes - 1,  # CORAL convention
        )
        print(f"  Using CORAL ordinal regression ({num_classes-1} cumulative thresholds)")
    else:
        # Standard: num_classes outputs
        model = smp.Unet(
           encoder_name=encoder_name,
           encoder_weights=encoder_weights,
           in_channels=in_channels,
           classes=num_classes,
        )
        print(f"  Using standard categorical classification ({num_classes} classes)")
    
    # Multi-GPU
    if torch.cuda.device_count() > 1:
        print(f"Using {torch.cuda.device_count()} GPUs with DataParallel")
        model = nn.DataParallel(model)
    
    model = model.to(device)
    
    # Loss function
    if use_ordinal:
        criterion = None  # CORAL loss computed directly in training loop
    else:
        class_weights_tensor = torch.FloatTensor(class_weights).to(device)
        criterion = MaskedCrossEntropyLoss(weight=class_weights_tensor, ignore_index=255)
    
    # Optimizer
    optimizer = torch.optim.Adam(model.parameters(), lr=learning_rate, weight_decay=weight_decay)
    
    # Training configuration
    training_config = {
        'use_ordinal': use_ordinal,
        'num_classes': num_classes,
        'ignore_index': 255,
        'gradient_clip_max_norm': gradient_clip_max_norm
    }
    
    # Track metrics
    history = {
        'train_loss': [],
        'val_loss': [],
        'val_ccr': [],
        'class_ccr': {c: [] for c in range(num_classes)},
        'test_epochs': [],
        'test_ccr': [],
        'test_class_ccr': {c: [] for c in range(num_classes)},
    }
    
    print("\n" + "="*60)
    print("Starting training...")
    print("="*60)
    
    has_val  = len(validate_loader) > 0
    has_test = len(test_loader) > 0

    for epoch in range(n_epochs):
        # Train
        train_loss = train_one_epoch(model, train_loader, criterion, optimizer, device, training_config)
        history['train_loss'].append(train_loss)

        # Validate
        if has_val:
            validate_loss, validate_acc, class_acc = validate(model, validate_loader, criterion, device, training_config)
            history['val_loss'].append(validate_loss)
            history['val_ccr'].append(validate_acc)
            for c in range(num_classes):
                history['class_ccr'][c].append(class_acc[c])

        # Test (every test_interval epochs)
        run_test = has_test and ((epoch + 1) % test_interval == 0 or epoch == n_epochs - 1)
        if run_test:
            _, test_acc, test_class_acc = validate(model, test_loader, criterion, device, training_config)
            history['test_epochs'].append(epoch + 1)
            history['test_ccr'].append(test_acc)
            for c in range(num_classes):
                history['test_class_ccr'][c].append(test_class_acc[c])

        # Print progress
        if has_val:
            print(f"\nEpoch {epoch+1}/{n_epochs}")
            print(f"  Train Loss: {train_loss:.4f}")
            print(f"  Validate Loss:   {validate_loss:.4f}")
            print(f"  Validate CCR:    {validate_acc:.2%}")
            print(f"  Class CCR:  ", end="")
            for c, acc in enumerate(class_acc):
                print(f"C{int(original_classes[c])}={acc:.2%} ", end="")
            if run_test:
                print(f"\n  Test CCR:        {test_acc:.2%}", flush=True)
            else:
                print(flush=True)
        else:
            line = f"Epoch {epoch+1}/{n_epochs} | train loss: {train_loss:.4f}"
            if run_test:
                line += f" | test CCR: {test_acc:.2%}"
            print(line, flush=True)
        

    # Compute best CCR summaries from history
    if has_val and history['val_ccr']:
        best_val_ccr   = max(history['val_ccr'])
        best_val_epoch = history['val_ccr'].index(best_val_ccr) + 1
    else:
        best_val_ccr = best_val_epoch = None

    if has_test and history['test_ccr']:
        best_test_ccr   = max(history['test_ccr'])
        best_test_epoch = history['test_epochs'][history['test_ccr'].index(best_test_ccr)]
    else:
        best_test_ccr = best_test_epoch = None

    # Save final model
    os.makedirs(output_dir, exist_ok=True)
    model_path = os.path.join(output_dir, f"unet_{site}_best.pth")
    config_path = os.path.join(output_dir, f"unet_{site}_config.json")

    if isinstance(model, nn.DataParallel):
        torch.save(model.module.state_dict(), model_path)
    else:
        torch.save(model.state_dict(), model_path)

    import json
    config = {
        'encoder_name': encoder_name,
        'encoder_weights': encoder_weights,
        'in_channels': in_channels,
        'num_classes': num_classes,
        'original_classes': original_classes,
        'site': site,
        'use_ordinal': use_ordinal
    }
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2)

    # Write training metrics CSV for R plotting
    import csv
    metrics_path = os.path.join(output_dir, 'training_metrics.csv')
    class_col_names = [f'test_ccr_class{int(original_classes[c])}' for c in range(num_classes)]
    header = ['epoch', 'train_loss', 'val_loss', 'val_ccr', 'test_ccr'] + class_col_names
    test_epoch_lookup = {ep: idx for idx, ep in enumerate(history['test_epochs'])}

    with open(metrics_path, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=header)
        writer.writeheader()
        for ep_idx in range(n_epochs):
            ep = ep_idx + 1
            row = {
                'epoch':      ep,
                'train_loss': history['train_loss'][ep_idx],
                'val_loss':   history['val_loss'][ep_idx] if has_val else '',
                'val_ccr':    history['val_ccr'][ep_idx]  if has_val else '',
                'test_ccr':   '',
            }
            for col in class_col_names:
                row[col] = ''
            if ep in test_epoch_lookup:
                test_idx = test_epoch_lookup[ep]
                row['test_ccr'] = history['test_ccr'][test_idx]
                for c in range(num_classes):
                    row[class_col_names[c]] = history['test_class_ccr'][c][test_idx]
            writer.writerow(row)

    print("\n" + "="*60)
    print("Training complete!")
    if best_val_ccr is not None:
        print(f"Best validation CCR: {best_val_ccr:.2%} (epoch {best_val_epoch})")
    if best_test_ccr is not None:
        print(f"Best test CCR:       {best_test_ccr:.2%} (epoch {best_test_epoch})")
    print(f"Model saved to: {model_path}")
    print(f"Metrics saved to: {metrics_path}")
    print("="*60)

    return model_path, best_test_ccr or best_val_ccr or 0.0
