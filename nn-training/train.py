from pathlib import Path
from typing import Any
from typing import Iterator

import numpy as np
import tensorflow as tf

OPTIMIZER = "adam"
NUM_EPOCHS = 10
NUM_REPRESENTATIVE_DATASET_SAMPLES = 100
MODEL_SAVE_PATH = "model.tflite"


def main() -> None:
    (train_images, train_labels), (test_images, test_labels) = get_dataset()
    model = train_model(train_images, train_labels, test_images, test_labels)
    model.summary()

    def representative_data_gen() -> Iterator:
        for input_value in (
            tf.data.Dataset.from_tensor_slices(train_images).batch(1).take(100)
        ):
            yield [input_value]

    quantized_model = quantize_model(
        model, tf.lite.RepresentativeDataset(representative_data_gen)
    )
    tflite_model_file = Path(MODEL_SAVE_PATH)
    tflite_model_file.write_bytes(quantized_model)


def get_dataset() -> tuple[
    tuple[np.ndarray, np.ndarray], tuple[np.ndarray, np.ndarray]
]:
    (train_images, train_labels), (test_images, test_labels) = (
        tf.keras.datasets.mnist.load_data()
    )
    # Binarize image pixels
    train_images = (train_images.astype(np.float32) / 255.0 >= 0.5).astype(np.float32)
    test_images = (test_images.astype(np.float32) / 255.0 >= 0.5).astype(np.float32)
    return (train_images, train_labels), (test_images, test_labels)


def train_model(
    train_images: np.ndarray,
    train_labels: np.ndarray,
    test_images: np.ndarray,
    test_labels: np.ndarray,
) -> tf.keras.Model:
    model = tf.keras.Sequential(
        [
            tf.keras.layers.InputLayer(input_shape=(28, 28)),
            tf.keras.layers.Reshape(target_shape=(28, 28, 1)),
            tf.keras.layers.Conv2D(filters=1, kernel_size=(3, 3), activation="relu"),
            tf.keras.layers.MaxPooling2D(pool_size=(2, 2)),
            tf.keras.layers.Conv2D(filters=3, kernel_size=(3, 3), activation="relu"),
            tf.keras.layers.MaxPooling2D(pool_size=(2, 2)),
            tf.keras.layers.Flatten(),
            tf.keras.layers.Dense(10),
        ]
    )
    model.compile(
        optimizer=OPTIMIZER,
        loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True),
        metrics=["accuracy"],
    )
    model.fit(
        train_images,
        train_labels,
        epochs=NUM_EPOCHS,
        validation_data=(test_images, test_labels),
    )
    return model


def quantize_model(
    model: tf.keras.Model, representative_dataset: tf.lite.RepresentativeDataset
) -> Any:
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = {tf.lite.Optimize.DEFAULT}
    converter.representative_dataset = representative_dataset
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    converter.inference_input_type = converter.inference_output_type = tf.uint8
    tflite_model = converter.convert()
    return tflite_model


if __name__ == "__main__":
    main()
