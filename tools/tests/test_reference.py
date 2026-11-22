import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "reference_model"))

from scratch_reference import count_candidates, detect_candidates


class ScratchReferenceTests(unittest.TestCase):
    def test_flat_field_has_no_candidates(self):
        image = [[128] * 8 for _ in range(8)]
        self.assertEqual(count_candidates(detect_candidates(image)), 0)

    def test_dark_vertical_line_is_detected(self):
        image = [[200] * 8 for _ in range(8)]
        for y in range(1, 7):
            image[y][3] = 40
        mask = detect_candidates(image, threshold=20)
        self.assertTrue(any(mask[y][3] for y in range(1, 7)))

    def test_image_shape_is_validated(self):
        with self.assertRaises(ValueError):
            detect_candidates([[0, 1], [2]])


if __name__ == "__main__":
    unittest.main()
