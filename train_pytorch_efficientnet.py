"""
Alzheimer's MRI Classification — PyTorch EfficientNetB0 (Optimized for RTX Native)
==================================================================================
Optimizations applied:
  - Translated directly from TensorFlow to PyTorch.
  - Native CUDA 13.x detection out of the box (uses RTX 5050 transparently).
  - Mixed Precision training using torch.amp for fast generation and VRAM efficiency.
  - VRAM-friendly batching with native PyTorch memory allocators.
  - 2-Phase training: Classifier Head -> Progressive Unfreeze of top Feature blocks.
"""

import os
import time
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader
from torchvision import datasets, transforms, models
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import classification_report, confusion_matrix
import numpy as np
from tqdm import tqdm

# ─────────────────────────────────────────────
# 1. HARDWARE SETUP
# ─────────────────────────────────────────────

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"[*] Target Device: {device}")
if device.type == "cuda":
    print(f"[*] GPU Name: {torch.cuda.get_device_name(0)}")
    torch.backends.cudnn.benchmark = True # Optimize cuDNN for static input shapes

# ─────────────────────────────────────────────
# 2. CONFIG
# ─────────────────────────────────────────────

TRAIN_DIR  = r"D:\Dataset\dataset\train"
VAL_DIR    = r"D:\Dataset\dataset\test"
IMG_SIZE   = 224
BATCH_SIZE = 48  # Tested up to 48 safely since caching is handled transparently

EPOCHS_P1  = 8     # Phase 1: Train Head
EPOCHS_P2  = 8     # Phase 2: Fine-Tuning
LR         = 1e-4
DROPOUT    = 0.3
SAVE_PATH  = r"d:\Alz-AI\backend\app\models\mri\efficientnet_v1_torch.pth"

# ─────────────────────────────────────────────
# 3. DATA PIPELINE
# ─────────────────────────────────────────────

print("\n[*] Initializing Data Loaders...")

# PyTorch ImageNet stats
normalize = transforms.Normalize(mean=[0.485, 0.456, 0.406],
                                 std=[0.229, 0.224, 0.225])

train_transform = transforms.Compose([
    transforms.Resize((IMG_SIZE, IMG_SIZE)),
    transforms.RandomHorizontalFlip(),
    transforms.RandomRotation(5), # 5 degrees is ~0.08 radians equivalent
    transforms.ColorJitter(contrast=0.1),
    transforms.ToTensor(),
    normalize,
])

val_transform = transforms.Compose([
    transforms.Resize((IMG_SIZE, IMG_SIZE)),
    transforms.ToTensor(),
    normalize,
]) # NOTE: Validation doesn't randomize

# Let datasets load paths lazily
train_dataset = datasets.ImageFolder(TRAIN_DIR, transform=train_transform)
val_dataset = datasets.ImageFolder(VAL_DIR, transform=val_transform)

class_names = train_dataset.classes

# Pinned memory + multiprocessing to keep GPU absolutely saturated
train_loader = DataLoader(train_dataset, batch_size=BATCH_SIZE, shuffle=True, 
                          num_workers=0, pin_memory=(device.type == 'cuda'))
val_loader = DataLoader(val_dataset, batch_size=BATCH_SIZE, shuffle=False, 
                        num_workers=0, pin_memory=(device.type == 'cuda'))

print(f"[*] Classes ({len(class_names)}): {class_names}")
print(f"[*] Train images: {len(train_dataset)}")
print(f"[*] Val images: {len(val_dataset)}")

# ─────────────────────────────────────────────
# 4. MODEL ARCHITECTURE
# ─────────────────────────────────────────────

def build_model(num_classes):
    print("\n[*] Loading EfficientNetB0...")
    model = models.efficientnet_b0(weights=models.EfficientNet_B0_Weights.IMAGENET1K_V1)
    
    # Phase 1: Freeze all feature extraction layers
    for param in model.parameters():
        param.requires_grad = False
        
    # Rebuild Classifier Head (this is automatically trainable)
    num_features = model.classifier[1].in_features
    model.classifier = nn.Sequential(
        nn.Dropout(p=DROPOUT, inplace=True),
        nn.Linear(num_features, 256),
        nn.ReLU(),
        nn.Dropout(p=DROPOUT),
        nn.Linear(256, num_classes)
    )
    
    return model.to(device)

def unfreeze_top_layers(model, num_blocks=2):
    """
    Progressively unfreezes the last `num_blocks` inside EfficientNet features.
    EfficientNet features list: [-1] = Conv2dNormActivation, [-2] = MBConv, etc.
    """
    for param in model.features[-num_blocks:].parameters():
        param.requires_grad = True
    print(f"\n[*] Unfrozen the last {num_blocks} feature blocks for Fine-Tuning.")

# ─────────────────────────────────────────────
# 5. TRAINING RUNNER 
# ─────────────────────────────────────────────

scaler = torch.amp.GradScaler('cuda' if device.type == 'cuda' else 'cpu')

def train_epoch(model, loader, optimizer, criterion):
    model.train()
    running_loss, correct, total = 0.0, 0, 0

    pbar = tqdm(loader, desc="  Training", leave=False)
    for inputs, labels in pbar:
        inputs, labels = inputs.to(device), labels.to(device)
        optimizer.zero_grad()

        # Automatic Mixed Precision to drastically cut VRAM usage and boost speed
        with torch.amp.autocast('cuda' if device.type == 'cuda' else 'cpu'):
            outputs = model(inputs)
            loss = criterion(outputs, labels)

        scaler.scale(loss).backward()
        scaler.step(optimizer)
        scaler.update()

        running_loss += loss.item() * inputs.size(0)
        _, predicted = outputs.max(1)
        total += labels.size(0)
        correct += predicted.eq(labels).sum().item()
        pbar.set_postfix({"Loss": loss.item()})

    return running_loss / total, correct / total

def val_epoch(model, loader, criterion):
    model.eval()
    running_loss, correct, total = 0.0, 0, 0
    all_preds, all_labels = [], []

    with torch.no_grad():
        for inputs, labels in tqdm(loader, desc="  Validation", leave=False):
            inputs, labels = inputs.to(device), labels.to(device)
            
            with torch.amp.autocast('cuda' if device.type == 'cuda' else 'cpu'):
                outputs = model(inputs)
                loss = criterion(outputs, labels)

            running_loss += loss.item() * inputs.size(0)
            _, predicted = outputs.max(1)
            total += labels.size(0)
            correct += predicted.eq(labels).sum().item()
            
            all_preds.extend(predicted.cpu().numpy())
            all_labels.extend(labels.cpu().numpy())

    return running_loss / total, correct / total, all_preds, all_labels

def evaluate_and_plot(train_acc, val_acc, train_loss, val_loss, y_true, y_pred, split_idx):
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 4))
    
    ax1.plot(train_acc, label="Train Acc")
    ax1.plot(val_acc, label="Val Acc")
    ax1.axvline(x=split_idx, color="gray", linestyle="--", alpha=0.5, label="Fine-tune start")
    ax1.set_title("Accuracy")
    ax1.legend()

    ax2.plot(train_loss, label="Train Loss")
    ax2.plot(val_loss, label="Val Loss")
    ax2.axvline(x=split_idx, color="gray", linestyle="--", alpha=0.5)
    ax2.set_title("Loss")
    ax2.legend()
    
    plt.tight_layout()
    plt.savefig("training_curves_pytorch.png", dpi=150)
    plt.close()
    
    cm = confusion_matrix(y_true, y_pred)
    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt="d", cmap="Blues", xticklabels=class_names, yticklabels=class_names)
    plt.title("Confusion Matrix")
    plt.ylabel("True Label")
    plt.xlabel("Predicted Label")
    plt.tight_layout()
    plt.savefig("confusion_matrix_pytorch.png", dpi=150)
    plt.close()
    
    print("\n--- Classification Report ---")
    print(classification_report(y_true, y_pred, target_names=class_names))

# ─────────────────────────────────────────────
# 6. MAIN ORCHESTRATION
# ─────────────────────────────────────────────

def main():
    model = build_model(len(class_names))
    criterion = nn.CrossEntropyLoss()
    
    # Store metrics for plotting
    history = {"train_acc": [], "val_acc": [], "train_loss": [], "val_loss": []}
    best_val_acc = 0.0
    
    print("\n=============================================")
    print("--- PHASE 1: Training Classification Head ---")
    print("=============================================")
    optimizer = optim.Adam(model.classifier.parameters(), lr=LR, weight_decay=1e-4) # L2 applied here
    scheduler = optim.lr_scheduler.ReduceLROnPlateau(optimizer, mode='max', factor=0.3, patience=2)

    for epoch in range(EPOCHS_P1):
        print(f"\nPhase 1 | Epoch {epoch+1}/{EPOCHS_P1}")
        t_loss, t_acc = train_epoch(model, train_loader, optimizer, criterion)
        v_loss, v_acc, final_preds, final_true = val_epoch(model, val_loader, criterion)
        
        history["train_loss"].append(t_loss); history["val_loss"].append(v_loss)
        history["train_acc"].append(t_acc); history["val_acc"].append(v_acc)
        
        print(f"Train Loss: {t_loss:.4f} | Acc: {t_acc:.4f} || Val Loss: {v_loss:.4f} | Acc: {v_acc:.4f}")
        scheduler.step(v_acc)
        
        if v_acc > best_val_acc:
            best_val_acc = v_acc
            torch.save(model.state_dict(), SAVE_PATH)
            print("  -> Best model saved!")

    split_index = len(history["train_acc"]) - 1
            
    print("\n=============================================")
    print("--- PHASE 2: Fine-Tuning Top Layers ---")
    print("=============================================")
    
    # Load best weights before unfrezzing to ensure we fine-tune off the best checkpoint
    if os.path.exists(SAVE_PATH):
        model.load_state_dict(torch.load(SAVE_PATH, weights_only=True))
        
    unfreeze_top_layers(model, num_blocks=3) 
    
    # Use much lower LR and include all parameters
    optimizer = optim.Adam(filter(lambda p: p.requires_grad, model.parameters()), lr=LR / 10, weight_decay=1e-4)
    scheduler = optim.lr_scheduler.ReduceLROnPlateau(optimizer, mode='max', factor=0.3, patience=2)
    
    # Reset patience trackers if you want EarlyStopping logic here manually (implied by plateau)

    for epoch in range(EPOCHS_P2):
        print(f"\nPhase 2 | Epoch {epoch+1}/{EPOCHS_P2}")
        t_loss, t_acc = train_epoch(model, train_loader, optimizer, criterion)
        v_loss, v_acc, final_preds, final_true = val_epoch(model, val_loader, criterion)
        
        history["train_loss"].append(t_loss); history["val_loss"].append(v_loss)
        history["train_acc"].append(t_acc); history["val_acc"].append(v_acc)
        
        print(f"Train Loss: {t_loss:.4f} | Acc: {t_acc:.4f} || Val Loss: {v_loss:.4f} | Acc: {v_acc:.4f}")
        scheduler.step(v_acc)
        
        if v_acc > best_val_acc:
            best_val_acc = v_acc
            torch.save(model.state_dict(), SAVE_PATH)
            print("  -> Best model saved!")
            
    evaluate_and_plot(history["train_acc"], history["val_acc"], 
                      history["train_loss"], history["val_loss"], 
                      final_true, final_preds, split_index)

if __name__ == "__main__":
    main()
