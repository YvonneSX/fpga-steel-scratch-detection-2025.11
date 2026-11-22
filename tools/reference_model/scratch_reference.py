"""Pure-Python reference for the FPGA 3x3 cross local-contrast detector."""

from __future__ import annotations


def detect_candidates(image: list[list[int]], threshold: int = 20) -> list[list[int]]:
    """Return a binary candidate mask using abs(4*C - N-S-E-W) // 4.

    Border pixels are zero because a complete 3x3 cross neighborhood is not
    available there. Input values must be 8-bit grayscale integers.
    """
    if not image or not image[0]:
        raise ValueError("image must not be empty")
    width = len(image[0])
    if any(len(row) != width for row in image):
        raise ValueError("image rows must have equal width")
    if not 0 <= threshold <= 255:
        raise ValueError("threshold must be in [0, 255]")
    if any(not 0 <= pixel <= 255 for row in image for pixel in row):
        raise ValueError("pixels must be 8-bit grayscale values")

    height = len(image)
    mask = [[0] * width for _ in range(height)]
    for y in range(1, height - 1):
        for x in range(1, width - 1):
            center = image[y][x]
            surround = (
                image[y][x - 1]
                + image[y][x + 1]
                + image[y - 1][x]
                + image[y + 1][x]
            )
            contrast = abs(4 * center - surround) // 4
            mask[y][x] = int(contrast >= threshold)
    return mask


def count_candidates(mask: list[list[int]]) -> int:
    return sum(sum(row) for row in mask)
