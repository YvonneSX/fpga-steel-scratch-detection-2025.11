"""Run the Python detector reference on an 8-bit binary PGM (P5) image."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "reference_model"))
from scratch_reference import count_candidates, detect_candidates  # noqa: E402


def read_pgm(path: Path) -> list[list[int]]:
    data = path.read_bytes()
    # P5 headers allow comments; consume tokens before the binary payload.
    index = 0
    tokens: list[bytes] = []
    while len(tokens) < 4:
        while index < len(data) and data[index] in b" \t\r\n":
            index += 1
        if index < len(data) and data[index] == ord("#"):
            while index < len(data) and data[index] not in b"\r\n":
                index += 1
            continue
        start = index
        while index < len(data) and data[index] not in b" \t\r\n#":
            index += 1
        if start == index:
            raise ValueError("invalid PGM header")
        tokens.append(data[start:index])
    magic, width_b, height_b, maxval_b = tokens
    if magic != b"P5" or int(maxval_b) != 255:
        raise ValueError("only binary 8-bit PGM (P5, maxval 255) is supported")
    # Skip the required whitespace separator; do not consume payload bytes that
    # happen to be whitespace-valued grayscale samples.
    if index >= len(data) or data[index] not in b" \t\r\n":
        raise ValueError("missing PGM payload separator")
    if data[index:index + 2] == b"\r\n":
        index += 2
    else:
        index += 1
    width, height = int(width_b), int(height_b)
    payload = data[index:]
    if len(payload) != width * height:
        raise ValueError("PGM payload length does not match dimensions")
    return [list(payload[y * width:(y + 1) * width]) for y in range(height)]


def write_pgm(path: Path, image: list[list[int]]) -> None:
    height, width = len(image), len(image[0])
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("wb") as output:
        output.write(f"P5\n{width} {height}\n255\n".encode("ascii"))
        output.write(bytes(pixel for row in image for pixel in row))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("image", type=Path, help="input P5 PGM grayscale image")
    parser.add_argument("--threshold", type=int, default=20)
    parser.add_argument("--mask", type=Path, help="output candidate mask PGM")
    args = parser.parse_args()

    image = read_pgm(args.image)
    mask = detect_candidates(image, args.threshold)
    output = args.mask or args.image.with_name(args.image.stem + "_mask.pgm")
    write_pgm(output, [[255 * pixel for pixel in row] for row in mask])
    print(f"Image: {len(image[0])}x{len(image)}")
    print(f"Threshold: {args.threshold}")
    print(f"Candidate pixels: {count_candidates(mask)}")
    print(f"Mask: {output}")


if __name__ == "__main__":
    main()
