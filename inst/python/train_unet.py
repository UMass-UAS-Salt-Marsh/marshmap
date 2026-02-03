"""
Train U-Net for salt marsh gradient classification
Uses masked loss to handle sparse transect labels
"""


# Part 1: Imports and setup

"""
Train U-Net for salt marsh gradient classification
Uses masked loss to handle sparse transect labels
"""

import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
import segmentation_models_pytorch as smp
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
    """
    
    def __init__(self, patches, labels, masks):
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
        
        print(f"Dataset created:")
        print(f"  Patches shape: {self.patches.shape}")  # [N, C, H, W]
        print(f"  Labels shape: {self.labels.shape}")    # [N, H, W]
        print(f"  Masks shape: {self.masks.shape}")      # [N, H, W]
        
    def __len__(self):
        return len(self.patches)
    
    def __getitem__(self, idx):
        """Return one patch, label, and mask"""
        return self.patches[idx], self.labels[idx], self.masks[idx]


# Part 3: Masked loss function

class MaskedCrossEntropyLoss(nn.Module):
    """
    Cross-entropy loss that only computes loss on labeled pixels
    Ignores pixels where mask = 0
    """
    
    def __init__(self, ignore_index=255):
        super().__init__()
        self.ignore_index = ignore_index
        # Use PyTorch's built-in cross entropy with ignore_index
        self.criterion = nn.CrossEntropyLoss(ignore_index=ignore_index, reduction='mean')
    
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

def train_one_epoch(model, dataloader, criterion, optimizer, device):
    """Train for one epoch"""
    model.train()
    running_loss = 0.0
    
    for batch_idx, (patches, labels, masks) in enumerate(dataloader):
        # Move to GPU
        patches = patches.to(device)
        labels = labels.to(device)
        masks = masks.to(device)
        
        # Forward pass
        optimizer.zero_grad()
        outputs = model(patches)
        
        # Compute loss
        loss = criterion(outputs, labels, masks)
        
        # Backward pass
        loss.backward()
        optimizer.step()
        
        running_loss += loss.item()
    
    epoch_loss = running_loss / len(dataloader)
    return epoch_loss


# Part 5: Validation function

def validate(model, dataloader, criterion, device, num_classes=4):
    """Validate model and compute metrics"""
    model.eval()
    running_loss = 0.0
    correct = 0
    total = 0
    
    # For per-class metrics
    class_correct = [0] * num_classes
    class_total = [0] * num_classes
    
    with torch.no_grad():  # No gradients needed for validation
        for patches, labels, masks in dataloader:
            patches = patches.to(device)
            labels = labels.to(device)
            masks = masks.to(device)
            
            # Forward pass
            outputs = model(patches)
            
            # Compute loss
            loss = criterion(outputs, labels, masks)
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
    
    epoch_loss = running_loss / len(dataloader)
    overall_acc = correct / total if total > 0 else 0
    
    # Per-class accuracy
    class_acc = []
    for c in range(num_classes):
        if class_total[c] > 0:
            class_acc.append(class_correct[c] / class_total[c])
        else:
            class_acc.append(0.0)
    
    return epoch_loss, overall_acc, class_acc


# Part 6: Main training loop

def train_unet(data_dir, site, n_epochs=50, batch_size=8, learning_rate=0.001, 
               output_dir="models", num_classes=4, in_channels=8):
    """
    Main training function
    
    Args:
        data_dir: Directory containing numpy files
        site: Site name (e.g., "site1")
        n_epochs: Number of training epochs
        batch_size: Batch size for training
        learning_rate: Learning rate for optimizer
        output_dir: Where to save trained model
        num_classes: Number of classes (4 for your gradient)
        in_channels: Number of input channels (8 for your multispectral + DEM)
    """
    
    print("="*60)
    print(f"Training U-Net for {site}")
    print("="*60)
    
    # Set device
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"Using device: {device}")
    
    # Load data
    print("\nLoading training data...")
    train_patches = np.load(os.path.join(data_dir, f"{site}_train_patches.npy"))
    train_labels = np.load(os.path.join(data_dir, f"{site}_train_labels.npy"))
    train_masks = np.load(os.path.join(data_dir, f"{site}_train_masks.npy"))
    
    print("Loading validation data...")
    validate_patches = np.load(os.path.join(data_dir, f"{site}_validate_patches.npy"))
    validate_labels = np.load(os.path.join(data_dir, f"{site}_validate_labels.npy"))
    validate_masks = np.load(os.path.join(data_dir, f"{site}_validate_masks.npy"))
    
    # Create datasets
    print("\nCreating datasets...")
    train_dataset = MaskedPatchDataset(train_patches, train_labels, train_masks)
    validate_dataset = MaskedPatchDataset(validate_patches, validate_labels, validate_masks)
    
    # Create dataloaders
    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    validate_loader = DataLoader(validate_dataset, batch_size=batch_size, shuffle=False)
    
    print(f"\nTrain batches: {len(train_loader)}")
    print(f"Val batches: {len(validate_loader)}")
    
    # Create model
    print("\nBuilding U-Net model...")
    model = smp.Unet(
        encoder_name='resnet34',       # Encoder backbone
        encoder_weights='imagenet',    # Use pretrained weights
        in_channels=in_channels,       # 8 input channels
        classes=num_classes,           # 4 output classes
    )
    
    # Use both GPUs if available
    if torch.cuda.device_count() > 1:
        print(f"Using {torch.cuda.device_count()} GPUs with DataParallel")
        model = nn.DataParallel(model)
    
    model = model.to(device)
    
    # Loss and optimizer
    criterion = MaskedCrossEntropyLoss(ignore_index=255)
    optimizer = torch.optim.Adam(model.parameters(), lr=learning_rate)
    
    # Training loop
    print("\n" + "="*60)
    print("Starting training...")
    print("="*60)
    
    best_validate_acc = 0.0
    
    for epoch in range(n_epochs):
        # Train
        train_loss = train_one_epoch(model, train_loader, criterion, optimizer, device)
        
        # Validate
        validate_loss, validate_acc, class_acc = validate(model, validate_loader, criterion, device, num_classes)
        
        # Print progress
        print(f"\nEpoch {epoch+1}/{n_epochs}")
        print(f"  Train Loss: {train_loss:.4f}")
        print(f"  Val Loss:   {validate_loss:.4f}")
        print(f"  Val Acc:    {validate_acc:.2%}")
        print(f"  Class Acc:  ", end="")
        for c, acc in enumerate(class_acc):
            print(f"C{c}={acc:.2%} ", end="")
        print()
        
        # Save best model
        if validate_acc > best_validate_acc:
            best_validate_acc = validate_acc
            
            # Create output directory if needed
            os.makedirs(output_dir, exist_ok=True)
            
            # Save model
            model_path = os.path.join(output_dir, f"unet_{site}_best.pth")
            
            # Handle DataParallel wrapper
            if isinstance(model, nn.DataParallel):
                torch.save(model.module.state_dict(), model_path)
            else:
                torch.save(model.state_dict(), model_path)
            
            print(f"  → Saved best model (acc={best_validate_acc:.2%})")
    
    print("\n" + "="*60)
    print("Training complete!")
    print(f"Best validation accuracy: {best_validate_acc:.2%}")
    print(f"Model saved to: {model_path}")
    print("="*60)
    
    return model_path, best_validate_acc


# Example usage (will be called from R)
if __name__ == "__main__":
    # Test with your Site 1 data
    model_path, final_acc = train_unet(
        data_dir="X:/projects/uas/marshmap/data/rr/unet/unet01",
        site="rr",
        n_epochs=10,  # Start with 10 for testing
        batch_size=8,
        learning_rate=0.001
    )
