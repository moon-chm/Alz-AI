"""
Alzheimer's MRI Classification — EfficientNetB0 (Optimized)
==========================================================
Optimized for RTX GPU using Mixed Precision and tf.data.
Expected 4x-5x speedup over ResNet50 + ImageDataGenerator.
"""

import os
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path

import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers, Model
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.callbacks import (
    ModelCheckpoint, EarlyStopping, ReduceLROnPlateau, TensorBoard
)
from sklearn.metrics import classification_report, confusion_matrix
import warnings
warnings.filterwarnings("ignore")

# ─────────────────────────────────────────────
# 1. HARDWARE ACCELERATION (Mixed Precision)
# ─────────────────────────────────────────────
# This uses 16-bit floats where possible for 2x-3x speedup on NVIDIA 20/30/40/50 series.
# It handles the loss scaling automatically.
try:
    from tensorflow.keras import mixed_precision
    policy = mixed_precision.Policy('mixed_float16')
    mixed_precision.set_global_policy(policy)
    print(f"[*] Mixed precision enabled: {policy.name}")
except Exception as e:
    print(f"[!] Mixed precision not supported or failed: {e}")

# ─────────────────────────────────────────────
# 2. CONFIG
# ─────────────────────────────────────────────
TRAIN_DIR   = r"D:\Dataset\dataset\train"
VAL_DIR     = r"D:\Dataset\dataset\test"
IMG_SIZE    = (224, 224)
BATCH_SIZE  = 32
# Dramatically reduced epochs for transfer learning
EPOCHS_P1   = 10  
EPOCHS_P2   = 10
LR          = 1e-4
DROPOUT     = 0.3
SAVE_PATH   = r"d:\Alz-AI\backend\app\models\mri\resnet_v1.h5"  # Keeping filename consistent
SEED        = 42
tf.random.set_seed(SEED)
np.random.seed(SEED)

# ─────────────────────────────────────────────
# 3. FAST DATA PIPELINE (tf.data)
# ─────────────────────────────────────────────
def build_datasets(train_dir, val_dir, img_size, batch_size):
    # Modern directory loader (much faster than ImageDataGenerator)
    train_ds = tf.keras.utils.image_dataset_from_directory(
        train_dir,
        label_mode='categorical',
        image_size=img_size,
        batch_size=batch_size,
        shuffle=True,
        seed=SEED
    )
    
    val_ds = tf.keras.utils.image_dataset_from_directory(
        val_dir,
        label_mode='categorical',
        image_size=img_size,
        batch_size=batch_size,
        shuffle=False
    )

    # Capture class names before prefetching (which hides them)
    class_names = train_ds.class_names
    
    # Prefetch samples to GPU while CPU handles next batch
    AUTOTUNE = tf.data.AUTOTUNE
    train_ds = train_ds.cache().shuffle(1000).prefetch(buffer_size=AUTOTUNE)
    val_ds = val_ds.cache().prefetch(buffer_size=AUTOTUNE)
    
    return train_ds, val_ds, class_names

# ─────────────────────────────────────────────
# 4. GPU-ACCELERATED AUGMENTATION
# ─────────────────────────────────────────────
def get_augmentation_layer():
    return keras.Sequential([
        layers.RandomFlip("horizontal"),
        layers.RandomRotation(0.1),
        layers.RandomZoom(0.1),
        layers.RandomContrast(0.1),
    ], name="augmentation")

# ─────────────────────────────────────────────
# 5. MODEL — EfficientNetB0
# ─────────────────────────────────────────────
def build_model(num_classes, img_size, dropout=0.3):
    # EfficientNetB0 has internal scaling (don't rescale to 1/255 manually)
    base = EfficientNetB0(
        include_top=False,
        weights="imagenet",
        input_shape=(*img_size, 3),
    )
    base.trainable = False

    inputs = keras.Input(shape=(*img_size, 3))
    x = get_augmentation_layer()(inputs)
    x = base(x, training=False)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.BatchNormalization()(x)
    x = layers.Dropout(dropout)(x)
    x = layers.Dense(256, activation="relu")(x)
    x = layers.Dropout(dropout)(x)
    
    # Softmax output must be float32 for numeric stability in mixed precision
    outputs = layers.Dense(num_classes, activation="softmax", dtype='float32')(x)

    model = Model(inputs, outputs, name="AlzheimerEfficientNet")
    model.compile(
        optimizer=keras.optimizers.Adam(LR),
        loss="categorical_crossentropy",
        metrics=["accuracy", keras.metrics.AUC(name="auc")],
    )
    return model, base

# ─────────────────────────────────────────────
# 6. CALLBACKS
# ─────────────────────────────────────────────
def get_callbacks(save_path):
    return [
        ModelCheckpoint(save_path, monitor="val_accuracy", save_best_only=True, verbose=1),
        EarlyStopping(monitor="val_accuracy", patience=4, restore_best_weights=True, verbose=1),
        ReduceLROnPlateau(monitor="val_loss", factor=0.2, patience=2, min_lr=1e-7, verbose=1),
        TensorBoard(log_dir="logs/efficientnet_v1")
    ]

# ─────────────────────────────────────────────
# 7. EVALUATION & PLOTS
# ─────────────────────────────────────────────
def evaluate_and_plot(model, val_ds, class_names, history1, history2=None):
    def merge(h1, h2, key):
        v = h1.history.get(key, [])
        if h2: v += h2.history.get(key, [])
        return v

    acc = merge(history1, history2, "accuracy")
    val_acc = merge(history1, history2, "val_accuracy")
    
    plt.figure(figsize=(10, 4))
    plt.plot(acc, label="Train Acc")
    plt.plot(val_acc, label="Val Acc")
    plt.title("Model Convergence")
    plt.legend()
    plt.savefig("training_curves.png", dpi=150)
    plt.close()

    # Confusion Matrix
    y_true = []
    y_pred = []
    for x, y in val_ds:
        preds = model.predict(x, verbose=0)
        y_true.extend(np.argmax(y, axis=1))
        y_pred.extend(np.argmax(preds, axis=1))

    cm = confusion_matrix(y_true, y_pred)
    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt="d", cmap="Blues", xticklabels=class_names, yticklabels=class_names)
    plt.title("Confusion Matrix")
    plt.savefig("confusion_matrix.png", dpi=150)
    plt.close()
    
    print("\n--- Classification Report ---")
    print(classification_report(y_true, y_pred, target_names=class_names))

# ─────────────────────────────────────────────
# 8. MAIN
# ─────────────────────────────────────────────
def main():
    print(f"TensorFlow: {tf.__version__}")
    train_ds, val_ds, class_names = build_datasets(TRAIN_DIR, VAL_DIR, IMG_SIZE, BATCH_SIZE)
    num_classes = len(class_names)
    
    print(f"Classes: {class_names}")
    
    model, base = build_model(num_classes, IMG_SIZE, DROPOUT)
    # model.summary() # Skip for brevity in logs

    # PHASE 1: Classification Head only
    print("\n--- Phase 1: Training Classification Head ---")
    history1 = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=EPOCHS_P1,
        callbacks=get_callbacks(SAVE_PATH)
    )

    # PHASE 2: Fine-Tuning
    print("\n--- Phase 2: Fine-Tuning EfficientNet Layers ---")
    # Unfreeze top layers for deep feature refinement
    base.trainable = True
    # We keep most frozen, fine-tune only the last few blocks
    for layer in base.layers[:-20]:
        layer.trainable = False
        
    model.compile(
        optimizer=keras.optimizers.Adam(LR / 10),
        loss="categorical_crossentropy",
        metrics=["accuracy", keras.metrics.AUC(name="auc")]
    )
    
    history2 = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=EPOCHS_P2,
        callbacks=get_callbacks(SAVE_PATH)
    )

    # Wrap up
    model.load_weights(SAVE_PATH)
    model.save(SAVE_PATH)
    print(f"\n✔ Optimized Model saved → {SAVE_PATH}")
    
    evaluate_and_plot(model, val_ds, class_names, history1, history2)

if __name__ == "__main__":
    main()