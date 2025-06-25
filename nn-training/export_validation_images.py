from train import get_dataset

OUTPUT_PATH = "val_images.txt"


def main() -> None:
    _, (val_images, val_labels), _ = get_dataset()
    text = ""
    for image, label in zip(val_images, val_labels):
        pixels_text = "".join(str(int(pixel)) for pixel in image.ravel())
        assert len(pixels_text) == 784
        text += f"{pixels_text}{label}\n"
    with open(OUTPUT_PATH, "w") as f:
        f.write(text)


if __name__ == "__main__":
    main()
