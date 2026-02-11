"""
Train U-Net for salt marsh gradient classification
Uses masked loss to handle sparse transect labels
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
    - Multi-band input patches (8 channels)
    - Class labels (4 classes: 0, 1, 2, 3)
    - Masks (1 = labeled, 0 = unlabeled)
    - Ignore value 255 for unlabeled pixels
    - Augmentation (rotations and flips)
    """
    
    def __init__(self, patches, labels, masks, augment=True):
        """
        Args:
            patches: numpy array [N, H, W, C] - N patches, H×W size, C channels
            labels: numpy array [N, H, W] - class labels (0-3 or 255)
            masks: numpy array [N, H, W] - binary masks (1=labeled, 0=unlabeled)
        """
        self.patches = torch.from_numpy(patches).float()
        self.labels = torch.from_numpy(labels).long()
        self.masks = torch.from_numpy(masks).float()
        
        # PyTorch expects [N, C, H, W] not [N, H, W, C]
        # Permute from [N, H, W, C] to [N, C, H, W]
        self.patches = self.patches.permute(0, 3, 1, 2)
        self.augment = augment
        
        print(f"Dataset created:")
        print(f"  Patches shape: {self.patches.shape}")  # [N, C, H, W]
        print(f"  Labels shape: {self.labels.shape}")    # [N, H, W]
        print(f"  Masks shape: {self.masks.shape}")      # [N, H, W]
        
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
                k = random.randint(0, 3)  # Number of 90° rotations
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


# Part 3: Masked loss function

class MaskedCrossEntropyLoss(nn.Module):
    """
    Cross-entropy loss that only computes loss on labeled pixels
    Ignores pixels where mask = 0
    """
    
    def __init__(self, weight=None, ignore_index=255):  # Add weight parameter
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
        # Set unlabeled pixels to ignore_index
        target_masked = target.clone()
        target_masked[mask == 0] = self.ignore_index
        
        # Compute loss (will ignore pixels with ignore_index)
        loss = self.criterion(pred, target_masked)
        
        return loss



# Part 4: Training function

def train_one_epoch(model, dataloader, criterion, optimizer, device, max_norm=1.0):
    """Train for one epoch"""
    model.train()
    running_loss = 0.0
    nan_count = 0
    
    for batch_idx, (patches, labels, masks) in enumerate(dataloader):
        patches = patches.to(device)
        labels = labels.to(device)
        masks = masks.to(device)
        
        # Skip batches with no labeled pixels (can happen with sparse data + shuffling)
        if masks.sum() == 0:
            # Don't print every time, just count it
            nan_count += 1
            continue
        
        # Check for NaN in batch
        if torch.isnan(patches).any() or torch.isnan(labels.float()).any():
            print(f"  WARNING: NaN in input batch {batch_idx}")
            continue
        
        optimizer.zero_grad()
        outputs = model(patches)
        
        # Check outputs
        if torch.isnan(outputs).any() or torch.isinf(outputs).any():
            print(f"  WARNING: NaN/Inf in outputs at batch {batch_idx}")
            nan_count += 1
            continue
        
        loss = criterion(outputs, labels, masks)
        
        # Check loss
        if torch.isnan(loss) or torch.isinf(loss):
            print(f"  WARNING: NaN/Inf loss at batch {batch_idx}")
            print(f"    Output range: [{outputs.min():.4f}, {outputs.max():.4f}]")
            print(f"    Labeled pixels in batch: {masks.sum().item()}")
            print(f"    Labels range: [{labels[masks==1].min()}, {labels[masks==1].max()}]")  # NEW
            print(f"    Patches range: [{patches.min():.4f}, {patches.max():.4f}]")  # NEW
            
            # Check each sample in batch
            for i in range(patches.shape[0]):
                sample_mask = masks[i]
                if sample_mask.sum() > 0:
                    sample_labels = labels[i][sample_mask == 1]
                    sample_outputs = outputs[i]
                    print(f"    Sample {i}: {sample_mask.sum().item()} labeled pixels, "
                          f"labels={sample_labels.unique().tolist()}, "
                          f"output range=[{sample_outputs.min():.4f}, {sample_outputs.max():.4f}]")
            
            nan_count += 1
            continue
        
        loss.backward()
        grad_norm = torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm)
        optimizer.step()
        running_loss += loss.item()
    
    epoch_loss = running_loss / (len(dataloader) - nan_count) if (len(dataloader) - nan_count) > 0 else float('nan')
    
    if nan_count > 0:
        print(f"  → {nan_count} batches skipped due to NaN/Inf")
    
    return epoch_loss



# Part 5: Validation function

def validate(model, dataloader, criterion, device, num_classes=4):
    """Validate model and compute metrics"""
    model.eval()
    running_loss = 0.0
    correct = 0
    total = 0
    nan_count = 0  # NEW
    
    # For per-class metrics
    class_correct = [0] * num_classes
    class_total = [0] * num_classes
    
    with torch.no_grad():
        for patches, labels, masks in dataloader:
            patches = patches.to(device)
            labels = labels.to(device)
            masks = masks.to(device)
            
            # NEW: Skip batches with no labeled pixels
            if masks.sum() == 0:
                nan_count += 1
                continue
            
            # Forward pass
            outputs = model(patches)
            
            # Compute loss
            loss = criterion(outputs, labels, masks)
            
            # NEW: Check for NaN loss
            if torch.isnan(loss) or torch.isinf(loss):
                nan_count += 1
                continue
            
            running_loss += loss.item()
            
            # Get predictions (argmax over classes)
            _, predicted = torch.max(outputs, 1)
            
            # Only count labeled pixels (where mask = 1)
            mask_bool = masks.bool()
            
            # Overall accuracy
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
    
    # Per-class accuracy
    class_acc = []
    for c in range(num_classes):
        if class_total[c] > 0:
            class_acc.append(class_correct[c] / class_total[c])
        else:
            class_acc.append(0.0)
    
    return epoch_loss, overall_acc, class_acc



# Part 6: Progress plotting function

def plot_training_curves(history, best_epoch, best_val_acc, output_dir, site, original_classes):
    """
    Plot training curves and save to file
    
    Args:
        history: Dictionary with 'train_loss', 'val_loss', 'val_ccr', 'class_ccr'
        best_epoch: Epoch number with best validation accuracy
        best_val_acc: Best validation accuracy achieved
        output_dir: Where to save the plot
        site: Site name for filename
        original_classes: List of original class numbers for labels
    """
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
    gradient_clip_max_norm=1.0, num_classes=4, in_channels=8, plot_curves=True):

    """
    Main training function
    
    Args:
        site: Site's 3-letter code (e.g., "nor")
        data_dir: Directory containing numpy files
        output_dir: Where to save trained model and diagnostic plots
        original_classes: Optional list/array mapping internal class indices to original class numbers
           e.g., [3, 4, 5, 6] means class 0→3, class 1→4, etc.
        encoder_name: Pre-trained encoder to use   
        encoder_weights: Load pretrained ImageNet weights ("ImageNet", only when RGB!) or train from scratch (None)
        learning_rate: Learning rate for optimizer
        weight_decay: L2 regularization - penalizes large weights to prevent overfitting
        n_epochs: Number of training epochs
        batch_size: Batch size for training
        early_stopping_patience: Stop early if no improvement for specified numher of epochs
        gradient_clip_max_norm: How much to clip gradient?
        num_classes: Number of classes to fit
        in_channels: Number of input channels (8 for multispectral + NDVI + NDRE + DEM)
        plot_curves: Create diagnostic plot of fit progress in output_dir?
        
    """
    
    # Set up class mapping
    if original_classes is not None:
        original_classes = [int(x) for x in original_classes]  # Convert to ints
    else:
        original_classes = list(range(num_classes))
        
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
    
    
    # After loading train_patches, check input data 
    print("\nInput data ranges:")
    for c in range(train_patches.shape[3]):  # For each channel
        c_data = train_patches[:, :, :, c]
        print(f"  Channel {c}: min={c_data.min():.4f}, max={c_data.max():.4f}, "
              f"mean={c_data.mean():.4f}, std={c_data.std():.4f}")
    
    # Check for NaN/Inf
    print(f"\nNaN in patches: {np.isnan(train_patches).any()}")
    print(f"Inf in patches: {np.isinf(train_patches).any()}")
    print(f"NaN in labels: {np.isnan(train_labels).any()}")
    
    # Check label range
    unique_labels = np.unique(train_labels)
    print(f"\nUnique label values: {unique_labels}")
    
    # Check that num_classes is correct
    actual_classes = len(np.unique(train_labels[train_labels != 255]))
    assert actual_classes == num_classes, f"Found {actual_classes} classes but expected {num_classes}"
    
    
    # Calculate class weights
    print("\nCalculating class weights...")
    
    # ALWAYS count ALL classes (0 to num_classes-1), even if some have zero pixels
    class_pixel_counts = np.zeros(num_classes)
    
    for c in range(num_classes):  # 0, 1, 2, 3 - always all of them
        count = ((train_labels == c) & (train_masks == 1)).sum()
        class_pixel_counts[c] = float(count)
    
    print(f"\nClass pixel counts:")
    for i in range(num_classes):
        print(f"  Class {int(original_classes[i])} (internal {i}): {class_pixel_counts[i]:.0f} pixels")
    
    # Check for missing classes
    if np.any(class_pixel_counts == 0):
        zero_classes = [int(original_classes[i]) for i in range(num_classes) if class_pixel_counts[i] == 0]
        print(f"\nWARNING: Classes {zero_classes} have ZERO training pixels!")
        print("These classes cannot be learned. Consider removing them from your analysis.")
    
    # Compute weights (epsilon prevents division by zero)
    class_weights = 1.0 / (class_pixel_counts + 1e-6)
    class_weights = class_weights / class_weights.sum() * num_classes
    
    print(f"\nClass weights: {class_weights}")    
    
    
    # Create datasets
    print("\nCreating datasets...")
    train_dataset = MaskedPatchDataset(train_patches, train_labels, train_masks)
    validate_dataset = MaskedPatchDataset(validate_patches, validate_labels, validate_masks)
    
    # Create dataloaders
    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    validate_loader = DataLoader(validate_dataset, batch_size=batch_size, shuffle=False)
    
    print(f"\nTrain batches: {len(train_loader)}")
    print(f"Val batches: {len(validate_loader)}")
    
    
    # Can't use ImageNet weights with 8 channels (ImageNet is 3-channel RGB)
    if in_channels != 3 and encoder_weights == 'imagenet':
        print(f"WARNING: Cannot use ImageNet weights with {in_channels} channels.")
        print(f"Setting encoder_weights=None (training from scratch)")
        encoder_weights = None
    
    
    # Create model
    print("\nBuilding U-Net model...")
    model = smp.Unet(
       encoder_name=encoder_name,
       encoder_weights=encoder_weights,
       in_channels=in_channels,
       classes=num_classes,
    )
    
    # Use both GPUs if available
    if torch.cuda.device_count() > 1:
        print(f"Using {torch.cuda.device_count()} GPUs with DataParallel")
        model = nn.DataParallel(model)
    
    model = model.to(device)
    
    # Convert class_weights to torch tensor and move to device
    class_weights_tensor = torch.FloatTensor(class_weights).to(device)


    # Loss and optimizer
    criterion = MaskedCrossEntropyLoss(weight=class_weights_tensor, ignore_index=255)
    optimizer = torch.optim.Adam(model.parameters(), lr=learning_rate, weight_decay=1e-4)
    
    
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
    epochs_without_improvement = 0  # NEW
    
    for epoch in range(n_epochs):
        # Train
        train_loss = train_one_epoch(model, train_loader, criterion, optimizer, device)
        
        # Validate
        validate_loss, validate_acc, class_acc = validate(model, validate_loader, 
                                                          criterion, device, num_classes)
        
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
            epochs_without_improvement = 0  # NEW: reset counter
            
            os.makedirs(output_dir, exist_ok=True)
            model_path = os.path.join(output_dir, f"unet_{site}_best.pth")
            
            if isinstance(model, nn.DataParallel):
                torch.save(model.module.state_dict(), model_path)
            else:
                torch.save(model.state_dict(), model_path)
            
            print(f"  → Saved best model (CCR={best_validate_acc:.2%})")
        else:
            # NEW: Early stopping logic
            if early_stopping_patience is not None:
                epochs_without_improvement += 1
                print(f"  (No improvement for {epochs_without_improvement} epoch(s))")
                
                if epochs_without_improvement >= early_stopping_patience:
                    print(f"\n{'='*60}")
                    print(f"Early stopping triggered after {epoch+1} epochs")
                    print(f"No improvement for {early_stopping_patience} consecutive epochs")
                    print(f"{'='*60}")
                    break
    
    print("\n" + "="*60)
    print("Training complete!")
    print(f"Best validation CCR: {best_validate_acc:.2%} (epoch {best_epoch})")
    print(f"Model saved to: {model_path}")
    print("="*60)
    
    # Plot training curves (optional)
    if plot_curves:
        print("\nGenerating training curves...")
        plot_training_curves(history, best_epoch, best_validate_acc, 
                           output_dir, site, original_classes)
    
    return model_path, best_validate_acc
