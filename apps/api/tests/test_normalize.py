"""Unit tests for the pure normalisation helpers.

Run with stdlib unittest (no third-party deps needed):
    python3 -m unittest discover -s apps/api/tests
"""

import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from reconsnap_api.normalize import (  # noqa: E402
    clean_pages,
    drop_repeated_lines,
    strip_page_artifacts,
)


class StripPageArtifactsTest(unittest.TestCase):
    def test_removes_page_markers_and_form_feeds(self):
        text = "Txn line 1\nPage 2 of 8\n\x0cTxn line 2"
        out = strip_page_artifacts(text)
        self.assertNotIn("Page 2 of 8", out)
        self.assertIn("Txn line 1", out)
        self.assertIn("Txn line 2", out)

    def test_keeps_lines_that_merely_contain_page(self):
        text = "01/05/2026 Page setup fee 10.00 90.00"
        self.assertIn("Page setup fee", strip_page_artifacts(text))


class DropRepeatedLinesTest(unittest.TestCase):
    def test_drops_header_repeated_across_pages(self):
        header = "Emirates NBD - Statement of Account"
        pages = [
            f"{header}\n01/05/2026 A 1.00 99.00",
            f"{header}\n02/05/2026 B 2.00 97.00",
        ]
        cleaned = drop_repeated_lines(pages)
        self.assertNotIn(header, "\n".join(cleaned))
        self.assertIn("01/05/2026 A 1.00 99.00", "\n".join(cleaned))

    def test_single_page_is_untouched(self):
        pages = ["Header\n01/05/2026 A 1.00 99.00"]
        self.assertEqual(drop_repeated_lines(pages), pages)


class CleanPagesTest(unittest.TestCase):
    def test_full_pipeline(self):
        header = "ACME BANK"
        pages = [
            f"{header}\n01/05/2026 Coffee 5.00 95.00\nPage 1 of 2",
            f"{header}\n02/05/2026 Salary 100.00 195.00\nPage 2 of 2",
        ]
        blob = clean_pages(pages)
        self.assertNotIn("ACME BANK", blob)
        self.assertNotIn("Page 1 of 2", blob)
        self.assertIn("Coffee", blob)
        self.assertIn("Salary", blob)


if __name__ == "__main__":
    unittest.main()
