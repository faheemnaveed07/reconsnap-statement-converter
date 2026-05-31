"""PDF text extraction using pdfplumber, with password handling.

Imports of the heavy third-party libraries are done lazily inside the
functions so that the pure helpers in this package (and the test suite) can be
imported without pdfplumber/pikepdf installed.
"""

from __future__ import annotations

from dataclasses import dataclass

from .normalize import clean_pages


class PasswordRequired(Exception):
    """Raised when the PDF is encrypted and no/incorrect password was given."""


class ExtractionError(Exception):
    """Raised when the PDF cannot be opened or contains no extractable text."""


@dataclass
class ExtractionResult:
    full_text: str
    pages: list[str]
    num_pages: int
    encrypted: bool
    # True when the document yielded no text layer (likely a scanned PDF that
    # would need OCR — the client can surface a clear message for this).
    needs_ocr: bool


def extract_pdf(data: bytes, password: str | None = None) -> ExtractionResult:
    """Extract clean text from PDF bytes.

    Raises PasswordRequired if the document is encrypted and the password is
    missing or wrong; ExtractionError for unreadable input.
    """
    import pdfplumber
    from pdfminer.pdfdocument import PDFPasswordIncorrect
    from pdfminer.pdfparser import PDFSyntaxError
    import io

    encrypted = False
    try:
        pdf = pdfplumber.open(io.BytesIO(data), password=password or "")
    except PDFPasswordIncorrect as exc:
        raise PasswordRequired("Incorrect or missing PDF password.") from exc
    except PDFSyntaxError as exc:
        raise ExtractionError("File is not a readable PDF.") from exc

    try:
        encrypted = bool(getattr(pdf, "is_encrypted", False)) or bool(password)
        page_texts = [(page.extract_text() or "") for page in pdf.pages]
        num_pages = len(pdf.pages)
    finally:
        pdf.close()

    full_text = clean_pages(page_texts)
    needs_ocr = num_pages > 0 and len(full_text.strip()) == 0

    return ExtractionResult(
        full_text=full_text,
        pages=page_texts,
        num_pages=num_pages,
        encrypted=encrypted,
        needs_ocr=needs_ocr,
    )
