"""Pure text-normalisation helpers for extracted statement pages.

These functions have no third-party dependencies so they can be unit-tested
without pdfplumber or a real PDF. They clean the raw text that the extractor
produces before it is handed back to the client:

  - strip page artifacts ("Page 3 of 8", form-feed characters);
  - drop boilerplate headers/footers that repeat on most pages (bank name,
    address, "Statement of Account"), which would otherwise confuse the
    client-side line parser.
"""

from __future__ import annotations

import math
import re
from collections import Counter

_PAGE_MARKER = re.compile(r"^\s*page\s+\d+\s*(?:of\s+\d+)?\s*$", re.IGNORECASE)
_FORM_FEED = "\x0c"


def strip_page_artifacts(text: str) -> str:
    """Remove form-feed characters and standalone 'Page X of Y' lines."""
    out = []
    for line in text.replace(_FORM_FEED, "\n").split("\n"):
        if _PAGE_MARKER.match(line):
            continue
        out.append(line.rstrip())
    return "\n".join(out)


def drop_repeated_lines(pages: list[str]) -> list[str]:
    """Remove lines that repeat across most pages (headers/footers).

    A line is considered boilerplate when its trimmed form is non-trivial
    (more than a couple of characters) and appears on at least half of the
    pages. Only applied when there are 2+ pages so single-page statements are
    left untouched.
    """
    if len(pages) < 2:
        return pages

    counts: Counter[str] = Counter()
    for page in pages:
        seen = {ln.strip() for ln in page.split("\n") if len(ln.strip()) > 2}
        counts.update(seen)

    # A boilerplate line must repeat on at least two pages AND on at least half
    # of them. The `max(2, ...)` guard stops unique transaction lines (which
    # appear on a single page) from being treated as boilerplate when there are
    # only two pages.
    threshold = max(2, math.ceil(len(pages) / 2))
    boilerplate = {line for line, n in counts.items() if n >= threshold}

    cleaned = []
    for page in pages:
        kept = [
            ln for ln in page.split("\n") if ln.strip() not in boilerplate
        ]
        cleaned.append("\n".join(kept))
    return cleaned


def clean_pages(pages: list[str]) -> str:
    """Run the full normalisation pipeline and return a single text blob."""
    stripped = [strip_page_artifacts(p) for p in pages]
    deboilerplated = drop_repeated_lines(stripped)
    blob = "\n".join(deboilerplated)
    # Collapse 3+ blank lines down to a single blank line.
    blob = re.sub(r"\n\s*\n\s*\n+", "\n\n", blob)
    return blob.strip()
