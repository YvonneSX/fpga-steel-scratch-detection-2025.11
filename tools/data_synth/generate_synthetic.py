"""Create a deterministic PGM steel-like surface with thin scratch defects."""

from __future__ import annotations

import argparse
import random
from pathlib import Path


def make_image(width: int, height: int, seed: int) -> list[list[int]]:
    rng = random.Random(seed)
    image = [
        [max(0, min(255, 176 + rng.randint(-5, 5))) for _ in range(width)]
        for _ in range(height)
    ]

    # A one-pixel diagonal dark scratch with mild variation in reflectance.
    for y in range(height // 5, (height * 4) // 5):
        x = width // 4 + (y - height // 5) // 3
        if 0 <= x < width:
            image[y][x] = 35 + (y % 9)
            if x + 1 < width and y % 5 == 0:
                image[y][x + 1] = 58

    # A shorter, brighter scratch provides a second polarity example.
    for x in range(width // 2, min(width - 1, (width * 3) // 4)):
        y = height * 2 // 3
        image[y][x] = 232
    return image


def write_pgm(path: Path, image: list[list[int]]) -> None:
    height, width = len(image), len(image[0])
    with path.open("wb") as output:
        output.write(f"P5\n{width} {height}\n255\n".encode("ascii"))
        output.write(bytes(pixel for row in image for pixel in row))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--width", type=int, default=320)
    parser.add_argument("--height", type=int, default=240)
    parser.add_argument("--seed", type=int, default=2023)
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).resolve().parents[2]
        / "assets"
        / "test_images"
        / "generated"
        / "synthetic_steel.pgm",
    )
    args = parser.parse_args()
    if args.width < 8 or args.height < 8:
        parser.error("width and height must both be at least 8")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    write_pgm(args.output, make_image(args.width, args.height, args.seed))
    print(f"Wrote {args.width}x{args.height} synthetic image to {args.output}")


if __name__ == "__main__":
    main()
