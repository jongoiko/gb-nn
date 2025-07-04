import math
import random
import struct
from pathlib import Path
from typing import Iterator

import numpy as np
import skimage
import tensorflow as tf
import tflite
from sklearn.model_selection import train_test_split

NUM_EPOCHS = 50
LEARNING_RATE = 5e-4
NUM_REPRESENTATIVE_DATASET_SAMPLES = 1000

MODEL_SAVE_PATH = "model.tflite"
SERIALIZED_SAVE_PATH = "model.bin"
TEST_SET_TXT_PATH = "test_set.txt"

SEED = 42
NUM_VAL_SAMPLES = 10000


def main() -> None:
    set_random_seeds()
    (
        (train_images, train_labels),
        (val_images, val_labels),
        (test_images, test_labels),
    ) = get_dataset()

    model = train_model(train_images, train_labels, val_images, val_labels)
    model.summary()

    def representative_data_gen() -> Iterator:
        for input_value in (
            tf.data.Dataset.from_tensor_slices(train_images)
            .batch(1)
            .take(NUM_REPRESENTATIVE_DATASET_SAMPLES)
        ):
            yield [input_value]

    quantized_model = quantize_model(
        model, tf.lite.RepresentativeDataset(representative_data_gen)
    )
    tflite_model_file = Path(MODEL_SAVE_PATH)
    tflite_model_file.write_bytes(quantized_model)
    val_accuracy = evaluate_quantized_accuracy(MODEL_SAVE_PATH, val_images, val_labels)
    print(f"Post-quantization validation accuracy: {val_accuracy * 100}%")

    with open(SERIALIZED_SAVE_PATH, "wb") as f:
        f.write(serialize_to_binary(MODEL_SAVE_PATH))

    # Save the test set to a .txt file to be read from the mGBA script
    text = ""
    for image, label in zip(test_images, test_labels):
        pixels_text = "".join(str(int(pixel)) for pixel in image.ravel())
        assert len(pixels_text) == 784
        text += f"{pixels_text}{label}\n"
    with open(TEST_SET_TXT_PATH, "w") as fd:
        fd.write(text)


def set_random_seeds() -> None:
    random.seed(SEED)
    np.random.seed(SEED)
    tf.random.set_seed(SEED)


def get_dataset() -> tuple[
    tuple[np.ndarray, np.ndarray],
    tuple[np.ndarray, np.ndarray],
    tuple[np.ndarray, np.ndarray],
]:
    (train_images, train_labels), (test_images, test_labels) = (
        tf.keras.datasets.mnist.load_data()
    )
    # Binarize image pixels
    train_images = (train_images.astype(np.float32) / 255.0 >= 0.5).astype(np.float32)
    test_images = (test_images.astype(np.float32) / 255.0 >= 0.5).astype(np.float32)

    # Skeletonize to have consistent (1-pixel) stroke width
    def skeletonize(image: np.ndarray) -> np.ndarray:
        binary_image = image > 0
        skeleton = skimage.morphology.skeletonize(binary_image)
        return (1.0 * skeleton).astype(image.dtype)

    train_images = np.stack(list(map(skeletonize, train_images)))
    test_images = np.stack(list(map(skeletonize, test_images)))
    # Split training set into training and validation
    train_images, val_images, train_labels, val_labels = train_test_split(
        train_images,
        train_labels,
        test_size=NUM_VAL_SAMPLES,
        random_state=SEED,
        shuffle=True,
        stratify=train_labels,
    )
    return (
        (train_images, train_labels),
        (val_images, val_labels),
        (test_images, test_labels),
    )


def train_model(
    train_images: np.ndarray,
    train_labels: np.ndarray,
    test_images: np.ndarray,
    test_labels: np.ndarray,
) -> tf.keras.Model:
    model = tf.keras.Sequential(
        [
            tf.keras.layers.InputLayer(input_shape=(28, 28)),
            tf.keras.layers.Flatten(),
            tf.keras.layers.Dense(14, activation="relu"),
            tf.keras.layers.Dense(30, activation="relu"),
            tf.keras.layers.Dense(10),
        ]
    )
    optimizer = tf.keras.optimizers.AdamW(learning_rate=LEARNING_RATE)
    model.compile(
        optimizer=optimizer,
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
) -> bytes:
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = {tf.lite.Optimize.DEFAULT}
    converter.representative_dataset = representative_dataset
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    converter.inference_input_type = converter.inference_output_type = tf.int8
    tflite_model = converter.convert()
    return tflite_model


def evaluate_quantized_accuracy(
    tflite_model_path: str, val_images: np.ndarray, val_labels: np.ndarray
) -> float:
    interpreter = tf.lite.Interpreter(model_path=tflite_model_path)
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()[0]
    output_details = interpreter.get_output_details()[0]

    correct_predictions = 0
    for image, label in zip(val_images, val_labels):
        if input_details["dtype"] == np.int8:
            input_scale, input_zero_point = input_details["quantization"]
            image = image / input_scale + input_zero_point
        image = np.expand_dims(image, axis=0).astype(input_details["dtype"])
        interpreter.set_tensor(input_details["index"], image)
        interpreter.invoke()
        output = interpreter.get_tensor(output_details["index"])[0]
        prediction = output.argmax()
        if prediction == label:
            correct_predictions += 1
    return correct_predictions / val_images.shape[0]


def serialize_to_binary(model_path: str) -> bytes:
    def pack_uint16(x: int) -> bytes:
        return struct.pack(">h", x)

    def pack_int32(x: int) -> bytes:
        return struct.pack(">i", x)

    def serialize_tensor_shape(tensor_idx: int) -> bytes:
        serialized = bytearray()
        weight_shape = tensor_details[tensor_idx]["shape"]
        serialized.append(len(weight_shape))
        for dim in weight_shape:
            serialized.extend(pack_uint16(dim))
        return serialized

    def serialize_operator(operator: tflite.Operator) -> bytes:
        def get_matmul_M(
            input1_scale: float, input2_scale: float, output_scale: float
        ) -> tuple[int, int]:
            M = input1_scale * input2_scale / output_scale
            M_0, exponent = math.frexp(M)
            n = -exponent
            M_0_fixed_point = int(round(M_0 * (1 << 15)))
            return M_0_fixed_point, n

        def has_relu(operator: tflite.Operator) -> bool:
            assert (
                operator.BuiltinOptionsType()
                == tflite.BuiltinOptions.FullyConnectedOptions
            )
            options = operator.BuiltinOptions()
            assert options is not None
            options_table = tflite.FullyConnectedOptions()
            options_table.Init(options.Bytes, options.Pos)
            activation = options_table.FusedActivationFunction()
            assert (
                activation == tflite.ActivationFunctionType.RELU
                or activation == tflite.ActivationFunctionType.NONE
            )
            return activation == tflite.ActivationFunctionType.RELU

        serialized = bytearray()
        opcode = model.OperatorCodes(operator.OpcodeIndex()).BuiltinCode()  # type: ignore
        if opcode == tflite.BuiltinOperator.FULLY_CONNECTED:
            serialized.append(opcode)
            input_tensor, weight, bias = [operator.Inputs(i) for i in range(3)]
            output = operator.Outputs(0)
            serialized.extend(serialize_tensor_shape(weight))
            (
                (input_scale, input_z),
                (weight_scale, _),
                (output_scale, output_z),
            ) = [
                tensor_details[tensor]["quantization"]
                for tensor in [input_tensor, weight, output]
            ]
            serialized.append(np.array(output_z).astype(np.uint8))
            M_0, n = get_matmul_M(input_scale, weight_scale, output_scale)
            serialized.extend(pack_uint16(M_0))
            serialized.append(np.array(n).astype(np.uint8))
            serialized.append(np.array(has_relu(operator)).astype(np.uint8))
            serialized.extend(interpreter.get_tensor(weight).ravel())
            # Pre-calculate q_bias:
            #       q_bias = q_b - Z_x * q_w
            for i, elem in enumerate(interpreter.get_tensor(bias)):
                q_bias = elem - input_z * interpreter.get_tensor(weight)[i].sum()
                serialized.extend(pack_int32(q_bias))
        return serialized

    with open(model_path, "rb") as f:
        buf = f.read()
        model = tflite.Model.GetRootAsModel(buf, 0)
    interpreter = tf.lite.Interpreter(model_path=model_path)
    tensor_details = interpreter.get_tensor_details()

    assert model.SubgraphsLength() == 1

    graph = model.Subgraphs(0)
    assert isinstance(graph, tflite.SubGraph)

    assert graph.InputsLength() == 1
    assert graph.OutputsLength() == 1

    serialized = bytearray()
    num_operators = 0
    for operator_idx in range(graph.OperatorsLength()):
        operator = graph.Operators(operator_idx)
        assert isinstance(operator, tflite.Operator)
        serialized_operator = serialize_operator(operator)
        if len(serialized_operator) > 0:
            num_operators += 1
        serialized.extend(serialized_operator)
    serialized.insert(0, num_operators)

    return serialized


if __name__ == "__main__":
    main()
