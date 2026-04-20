"""
Alzheimer's MRI Classification — EfficientNetB0 (Laptop-Safe Optimized)
========================================================================
Optimizations applied:
  - CPU handles data pipeline + augmentation (offloads GPU memory)
  - GPU handles model computation only
  - Mixed precision only if GPU is present (safe fallback)
  - Memory growth enabled to prevent GPU OOM crashes
  - Reduced fine-tuning scope (last 10 layers, not 20)
  - gradient_accumulation_steps trick replaced with smaller but safer batching
  - Progressive unfreezing instead of bulk unfreeze
  - .cache() only if dataset fits in RAM (configurable)
  - TensorBoard disabled by default (saves disk I/O)
"""

import os
import numpy as np
import matplotlib
matplotlib.use("Agg")          # Non-interactive backend — safe on laptops
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path

import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers, Model
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.callbacks import (
    ModelCheckpoint, EarlyStopping, ReduceLROnPlateau
)
from sklearn.metrics import classification_report, confusion_matrix
import warnings
warnings.filterwarnings("ignore")


# ─────────────────────────────────────────────
# 1. HARDWARE SETUP (Safe for Laptops)
# ─────────────────────────────────────────────

def setup_hardware():
    """
    Configures GPU memory growth + mixed precision.
    Memory growth = GPU allocates only what it needs, won't crash your system.
    Mixed precision is skipped if no compatible GPU is found.
    """
    gpus = tf.config.list_physical_devices("GPU")
    if gpus:
        try:
            for gpu in gpus:
                # CRITICAL for laptops: prevents TF from gobbling all VRAM upfront
                tf.config.experimental.set_memory_growth(gpu, True)
            print(f"[*] GPU found: {len(gpus)} device(s) — memory growth enabled")
        except RuntimeError as e:
            print(f"[!] GPU setup error: {e}")

        # Mixed precision: safe only with GPU
        try:
            from tensorflow.keras import mixed_precision
            policy = mixed_precision.Policy("mixed_float16")
            mixed_precision.set_global_policy(policy)
            print(f"[*] Mixed precision enabled: {policy.name}")
        except Exception as e:
            print(f"[!] Mixed precision skipped: {e}")
    else:
        print("[*] No GPU detected — running on CPU only")

    # Limit TF log noise
    os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"
    tf.get_logger().setLevel("ERROR")


# ─────────────────────────────────────────────
# 2. CONFIG
# ─────────────────────────────────────────────

TRAIN_DIR  = r"D:\Dataset\dataset\train"
VAL_DIR    = r"D:\Dataset\dataset\test"
IMG_SIZE   = (224, 224)

# ── Batch size tuning ──
# 32  → default (fine for 6GB+ VRAM)
# 16  → if you get OOM errors on GPU
# 8   → if running CPU-only
BATCH_SIZE = 48

EPOCHS_P1  = 8     # Head training — reduced, EarlyStopping will handle the rest
EPOCHS_P2  = 8     # Fine-tuning  — same logic
LR         = 1e-4
DROPOUT    = 0.3
SAVE_PATH  = r"d:\Alz-AI\backend\app\models\mri\efficientnet_v1.h5"

# Set to False if your dataset is large (> ~8GB images) to avoid RAM crash
CACHE_DATASET = False

SEED = 42
tf.random.set_seed(SEED)
np.random.seed(SEED)


# ─────────────────────────────────────────────
# 3. DATA PIPELINE
#    CPU handles all I/O and augmentation.
#    This frees GPU memory exclusively for the model.
# ─────────────────────────────────────────────

def build_datasets(train_dir, val_dir, img_size, batch_size):
    AUTOTUNE = tf.data.AUTOTUNE

    train_ds = tf.keras.utils.image_dataset_from_directory(
        train_dir,
        label_mode="categorical",
        image_size=img_size,
        batch_size=batch_size,
        shuffle=True,
        seed=SEED,
    )
    val_ds = tf.keras.utils.image_dataset_from_directory(
        val_dir,
        label_mode="categorical",
        image_size=img_size,
        batch_size=batch_size,
        shuffle=False,
    )

    class_names = train_ds.class_names
    num_classes = len(class_names)

    # ── Class imbalance check ──
    # Print sample counts per class so you know if weighting is needed
    print(f"\n[*] Classes ({num_classes}): {class_names}")
    for cls in class_names:
        count = len(list(Path(train_dir, cls).glob("*")))
        print(f"    {cls}: {count} images")

    # ── Augmentation on CPU (with_options pins ops to CPU) ──
    augment = keras.Sequential([
        layers.RandomFlip("horizontal"),
        layers.RandomRotation(0.08),       # Reduced — MRI is rotationally sensitive
        layers.RandomZoom(0.08),
        layers.RandomContrast(0.1),
    ], name="augmentation")

    def augment_batch(images, labels):
        return augment(images, training=True), labels

    # Pin augmentation to CPU explicitly
    cpu_device = "/cpu:0"
    with tf.device(cpu_device):
        if CACHE_DATASET:
            # Cache AFTER loading but BEFORE augmentation
            # This caches raw images to RAM, augmentation varies each epoch
            train_ds = (
                train_ds
                .cache()                            # Cache decoded images
                .map(augment_batch, num_parallel_calls=AUTOTUNE)
                .shuffle(buffer_size=500, seed=SEED)
                .prefetch(AUTOTUNE)
            )
        else:
            train_ds = (
                train_ds
                .map(augment_batch, num_parallel_calls=AUTOTUNE)
                .shuffle(buffer_size=500, seed=SEED)
                .prefetch(AUTOTUNE)
            )

        val_ds = (
            val_ds
            .cache()
            .prefetch(AUTOTUNE)
        )

    return train_ds, val_ds, class_names


# ─────────────────────────────────────────────
# 4. MODEL
# ─────────────────────────────────────────────

def build_model(num_classes, img_size, dropout=0.3):
    base = EfficientNetB0(
        include_top=False,
        weights="imagenet",
        input_shape=(*img_size, 3),
    )
    base.trainable = False   # Frozen for Phase 1

    inputs = keras.Input(shape=(*img_size, 3))
    # NOTE: EfficientNetB0 has internal preprocessing — do NOT rescale to 1/255
    x = base(inputs, training=False)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.BatchNormalization()(x)
    x = layers.Dropout(dropout)(x)
    x = layers.Dense(256, activation="relu", kernel_regularizer=keras.regularizers.l2(1e-4))(x)
    x = layers.Dropout(dropout)(x)

    # float32 output layer for numerical stability with mixed precision
    outputs = layers.Dense(num_classes, activation="softmax", dtype="float32")(x)

    model = Model(inputs, outputs, name="AlzheimerEfficientNet")
    return model, base


def compile_model(model, lr):
    model.compile(
        optimizer=keras.optimizers.Adam(lr),
        loss="categorical_crossentropy",
        metrics=["accuracy", keras.metrics.AUC(name="auc")],
    )


# ─────────────────────────────────────────────
# 5. CALLBACKS
# ─────────────────────────────────────────────

def get_callbacks(save_path, patience_es=5, patience_lr=2):
    return [
        ModelCheckpoint(
            save_path,
            monitor="val_accuracy",
            save_best_only=True,
            verbose=1,
        ),
        EarlyStopping(
            monitor="val_accuracy",
            patience=patience_es,       # Increased to 5 — gives model more room
            restore_best_weights=True,
            verbose=1,
        ),
        ReduceLROnPlateau(
            monitor="val_loss",
            factor=0.3,                 # Less aggressive than 0.2 — stable training
            patience=patience_lr,
            min_lr=1e-8,
            verbose=1,
        ),
        # TensorBoard removed — saves disk I/O and speeds up training
        # Re-add if you need it: TensorBoard(log_dir="logs/efficientnet_v1")
    ]


# ─────────────────────────────────────────────
# 6. PROGRESSIVE FINE-TUNING (Safer than bulk unfreeze)
# ─────────────────────────────────────────────

def unfreeze_top_layers(base, num_layers=10):
    """
    Unfreeze only the last N layers of EfficientNetB0.
    Fewer layers = faster training + less risk of catastrophic forgetting.
    num_layers=10 is a good starting point; bump to 20 if val_acc plateaus.
    """
    base.trainable = True
    for layer in base.layers[:-num_layers]:
        layer.trainable = False

    trainable_count = sum(1 for l in base.layers if l.trainable)
    print(f"[*] Fine-tuning: {trainable_count} / {len(base.layers)} base layers unfrozen")


# ─────────────────────────────────────────────
# 7. EVALUATION & PLOTS
# ─────────────────────────────────────────────

def evaluate_and_plot(model, val_ds, class_names, history1, history2=None):
    def merge(h1, h2, key):
        v = h1.history.get(key, [])
        if h2:
            v = v + h2.history.get(key, [])
        return v

    acc     = merge(history1, history2, "accuracy")
    val_acc = merge(history1, history2, "val_accuracy")
    loss    = merge(history1, history2, "loss")
    val_loss= merge(history1, history2, "val_loss")

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 4))
    ax1.plot(acc, label="Train Acc")
    ax1.plot(val_acc, label="Val Acc")
    ax1.axvline(x=len(history1.history["accuracy"]) - 1,
                color="gray", linestyle="--", alpha=0.5, label="Fine-tune start")
    ax1.set_title("Accuracy")
    ax1.legend()

    ax2.plot(loss, label="Train Loss")
    ax2.plot(val_loss, label="Val Loss")
    ax2.set_title("Loss")
    ax2.legend()

    plt.tight_layout()
    plt.savefig("training_curves.png", dpi=150)
    plt.close()
    print("[*] Saved: training_curves.png")

    # Confusion Matrix
    y_true, y_pred = [], []
    for x_batch, y_batch in val_ds:
        preds = model.predict(x_batch, verbose=0)
        y_true.extend(np.argmax(y_batch.numpy(), axis=1))
        y_pred.extend(np.argmax(preds, axis=1))

    cm = confusion_matrix(y_true, y_pred)
    plt.figure(figsize=(8, 6))
    sns.heatmap(
        cm, annot=True, fmt="d", cmap="Blues",
        xticklabels=class_names, yticklabels=class_names,
    )
    plt.title("Confusion Matrix")
    plt.ylabel("True Label")
    plt.xlabel("Predicted Label")
    plt.tight_layout()
    plt.savefig("confusion_matrix.png", dpi=150)
    plt.close()
    print("[*] Saved: confusion_matrix.png")

    print("\n--- Classification Report ---")
    print(classification_report(y_true, y_pred, target_names=class_names))


# ─────────────────────────────────────────────
# 8. MAIN
# ─────────────────────────────────────────────

def main():
    setup_hardware()
    print(f"[*] TensorFlow: {tf.__version__}")

    train_ds, val_ds, class_names = build_datasets(
        TRAIN_DIR, VAL_DIR, IMG_SIZE, BATCH_SIZE
    )
    num_classes = len(class_names)

    model, base = build_model(num_classes, IMG_SIZE, DROPOUT)
    compile_model(model, LR)

    # ── PHASE 1: Train classification head only ──
    print("\n--- Phase 1: Training Classification Head ---")
    history1 = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=EPOCHS_P1,
        callbacks=get_callbacks(SAVE_PATH, patience_es=5),
    )

    # ── PHASE 2: Fine-tune top layers ──
    print("\n--- Phase 2: Fine-Tuning Top Layers ---")
    unfreeze_top_layers(base, num_layers=10)   # Change to 20 if you want deeper fine-tuning
    compile_model(model, LR / 10)              # 10x lower LR for fine-tuning

    history2 = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=EPOCHS_P2,
        callbacks=get_callbacks(SAVE_PATH, patience_es=5),
    )

    # Save final best model
    model.load_weights(SAVE_PATH)
    model.save(SAVE_PATH)
    print(f"\n✔ Model saved → {SAVE_PATH}")

    evaluate_and_plot(model, val_ds, class_names, history1, history2)


if __name__ == "__main__":
    main()