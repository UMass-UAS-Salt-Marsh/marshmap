"""
Train U-Net for salt marsh gradient classification
Uses masked loss to handle sparse transect labels
Supports ordinal regression for ordered classes
"""

# Part 1: Imports and setup

import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
import segmentation_models_pytorch as smp
import torchvision.transforms as T
import torchvision.transforms.functional as TF
import random
import os
from pathlib import Path

# Try to import CORAL for ordinal regression
try:
    from coral_pytorch.dataset import corn_label_from_logits
    from coral_pytorch.losses import corn_loss
    CORAL_AVAILABLE = True
except ImportError:
    CORAL_AVAILABLE = False
    print("NOTE: coral_pytorch not available. Install with: pip install coral-pytorch")
    print("      Ordinal regression will not be available.")

# Set random seeds for reproducibility
torch.manual_seed(42)
np.random.seed(42)

print(f"PyTorch version: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"Number of GPUs: {torch.cuda.device_count()}")
    for i in range(torch.cuda.device_count()):
        print(f"  GPU {i}: {torch.cuda.get_device_name(i)}")


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


# Part 6: Progress plotting function

def plot_training_curves(history, best_epoch, best_val_acc, output_dir, site, original_classes):
    """Plot training curves and save to file"""
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    
    n_epochs = len(history['train_loss'])
    epochs = range(1, n_epochs + 1)
    num_classes = len(original_classes)
    
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    
    # Plot 1: Train vs Val Loss
    axes[0, 0].plot(epochs, history['train_loss'], 'b-', label='Train Loss', linewidth=2)
    axes[0, 0].plot(epochs, history['val_loss'], 'r-', label='Val Loss', linewidth=2)
    axes[0, 0].axvline(best_epoch, color='g', linestyle='--', alpha=0.5, 
                       label=f'Best epoch ({best_epoch})')
    axes[0, 0].set_xlabel('Epoch')
    axes[0, 0].set_ylabel('Loss')
    axes[0, 0].set_title('Training and Validation Loss')
    axes[0, 0].legend()
    axes[0, 0].grid(True, alpha=0.3)
    
    # Plot 2: Val CCR
    axes[0, 1].plot(epochs, [x*100 for x in history['val_ccr']], 'g-', linewidth=2)
    axes[0, 1].axvline(best_epoch, color='g', linestyle='--', alpha=0.5, 
                       label=f'Best: {best_val_acc:.1%}')
    axes[0, 1].axhline(best_val_acc*100, color='orange', linestyle='--', alpha=0.5)
    axes[0, 1].set_xlabel('Epoch')
    axes[0, 1].set_ylabel('CCR (%)')
    axes[0, 1].set_title('Validation CCR')
    axes[0, 1].legend()
    axes[0, 1].grid(True, alpha=0.3)
    axes[0, 1].set_ylim([0, 100])
    
    # Plot 3: Per-class CCR
    colors = ['blue', 'orange', 'green', 'red', 'purple', 'brown', 'pink', 'gray']
    for c in range(num_classes):
        axes[1, 0].plot(epochs, [x*100 for x in history['class_ccr'][c]], 
                       color=colors[c % len(colors)], 
                       label=f'Class {int(original_classes[c])}', 
                       linewidth=1.5)
    axes[1, 0].axvline(best_epoch, color='gray', linestyle='--', alpha=0.5)
    axes[1, 0].set_xlabel('Epoch')
    axes[1, 0].set_ylabel('CCR (%)')
    axes[1, 0].set_title('Per-Class CCR')
    axes[1, 0].legend()
    axes[1, 0].grid(True, alpha=0.3)
    axes[1, 0].set_ylim([0, 100])
    
    # Plot 4: Loss difference (overfitting indicator)
    loss_diff = [v - t for v, t in zip(history['val_loss'], history['train_loss'])]
    axes[1, 1].plot(epochs, loss_diff, 'purple', linewidth=2)
    axes[1, 1].axhline(0, color='black', linestyle='-', alpha=0.3)
    axes[1, 1].axvline(best_epoch, color='g', linestyle='--', alpha=0.5)
    axes[1, 1].set_xlabel('Epoch')
    axes[1, 1].set_ylabel('Val Loss - Train Loss')
    axes[1, 1].set_title('Overfitting Indicator (higher = more overfit)')
    axes[1, 1].grid(True, alpha=0.3)
    
    plt.tight_layout()
    plot_path = os.path.join(output_dir, f'training_curves_{site}.png')
    plt.savefig(plot_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"Training curves saved to: {plot_path}")
    return plot_path


# Part 7: Main training loop

def train_unet(site, data_dir, output_dir="models", original_classes=None, 
    encoder_name="resnet18", encoder_weights=None, learning_rate=0.0001, 
    weight_decay=1e-4, n_epochs=50, batch_size=8, early_stopping_patience=None, 
    gradient_clip_max_norm=1.0, num_classes=4, in_channels=8, plot_curves=True,
    use_ordinal=False):
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
        early_stopping_patience: Stop if no improvement for N epochs
        gradient_clip_max_norm: Gradient clipping threshold
        num_classes: Number of classes to fit
        in_channels: Number of input channels
        plot_curves: Create diagnostic plots?
        use_ordinal: Use ordinal regression for ordered classes (requires coral_pytorch)
    """
    
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
    
    # Set device
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
    
    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    validate_loader = DataLoader(validate_dataset, batch_size=batch_size, shuffle=False)
    
    print(f"\nTrain batches: {len(train_loader)}")
    print(f"Val batches: {len(validate_loader)}")
    
    # # Check encoder weights compatibility
    # if in_channels != 3 and encoder_weights == 'imagenet':
    #     print(f"WARNING: Cannot use ImageNet weights with {in_channels} channels.")
    #     print(f"Setting encoder_weights=None (training from scratch)")
    #     encoder_weights = None
    
    print(f"Encoder: {encoder_name}")
    print(f"Encoder weights: {encoder_weights}")
    
    # Create model
    print("\nBuilding U-Net model...")
    
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
        'class_ccr': {c: [] for c in range(num_classes)}
    }
    
    print("\n" + "="*60)
    print("Starting training...")
    print("="*60)
    
    best_validate_acc = 0.0
    best_epoch = 0
    epochs_without_improvement = 0
    
    for epoch in range(n_epochs):
        # Train
        train_loss = train_one_epoch(model, train_loader, criterion, optimizer, device, training_config)
        
        # Validate
        validate_loss, validate_acc, class_acc = validate(model, validate_loader, criterion, device, training_config)
        
        # Store metrics
        history['train_loss'].append(train_loss)
        history['val_loss'].append(validate_loss)
        history['val_ccr'].append(validate_acc)
        for c in range(num_classes):
            history['class_ccr'][c].append(class_acc[c])
        
        # Print progress
        print(f"\nEpoch {epoch+1}/{n_epochs}")
        print(f"  Train Loss: {train_loss:.4f}")
        print(f"  Validate Loss:   {validate_loss:.4f}")
        print(f"  Validate CCR:    {validate_acc:.2%}")
        print(f"  Class CCR:  ", end="")
        for c, acc in enumerate(class_acc):
            print(f"C{int(original_classes[c])}={acc:.2%} ", end="")
        print()
        
        # Save best model
        if validate_acc > best_validate_acc:
            best_validate_acc = validate_acc
            best_epoch = epoch + 1
            epochs_without_improvement = 0
            
            os.makedirs(output_dir, exist_ok=True)
            model_path = os.path.join(output_dir, f"unet_{site}_best.pth")
            config_path = os.path.join(output_dir, f"unet_{site}_config.json")
            
            # Save model weights
            if isinstance(model, nn.DataParallel):
                torch.save(model.module.state_dict(), model_path)
            else:
                torch.save(model.state_dict(), model_path)
            
            # Save model configuration
            import json
            config = {
                'encoder_name': encoder_name,
                'encoder_weights': encoder_weights,
                'in_channels': in_channels,
                'num_classes': num_classes,
                'original_classes': original_classes,
                'site': site,
                'use_ordinal': use_ordinal  # NEW
            }
            with open(config_path, 'w') as f:
                json.dump(config, f, indent=2)
            
            print(f"  → Saved best model (CCR={best_validate_acc:.2%})")
        else:
            # Early stopping
            if early_stopping_patience is not None:
                epochs_without_improvement += 1
                print(f"  (No improvement for {epochs_without_improvement} epoch(s))")
                
                if epochs_without_improvement >= early_stopping_patience:
                    print(f"\n{'='*60}")
                    print(f"Early stopping triggered after {epoch+1} epochs")
                    print(f"{'='*60}")
                    break
    
    print("\n" + "="*60)
    print("Training complete!")
    print(f"Best validation CCR: {best_validate_acc:.2%} (epoch {best_epoch})")
    print(f"Model saved to: {model_path}")
    print("="*60)
    
    # Plot training curves
    if plot_curves:
        print("\nGenerating training curves...")
        plot_training_curves(history, best_epoch, best_validate_acc, 
                           output_dir, site, original_classes)
    
    return model_path, best_validate_acc
