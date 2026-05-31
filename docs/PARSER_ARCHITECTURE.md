# Parser Architecture

## Goal

Create a parser engine that can start with deterministic templates and later support OCR/AI fallback without coupling extraction logic to Flutter UI.

## Core Interfaces

Planned Dart concepts:

- `StatementParser`
- `BankTemplate`
- `BankDetector`
- `PdfTextExtractor`
- `TransactionNormalizer`
- `ValidationEngine`
- `ExportEngine`

## Data Flow

1. User selects a statement file.
2. App checks file type and password status.
3. Text extraction attempts local digital-PDF parsing.
4. Bank detector tries fingerprints and layout hints.
5. Matching parser template extracts raw rows.
6. Normalizer converts raw rows into canonical transactions.
7. Validation engine checks balances and row quality.
8. User edits rows.
9. Export engine generates CSV first, XLSX later.

## Canonical Transaction Model

Fields:

- `id`
- `date`
- `description`
- `debit`
- `credit`
- `amount`
- `balance`
- `currency`
- `confidence`
- `sourcePage`
- `sourceLine`
- `notes`

## Validation Rules

MVP validation:

- Opening balance plus credits minus debits equals closing balance.
- Dates are parseable.
- Amounts are parseable.
- Running balance changes match row amounts when available.
- Duplicate rows are flagged.
- Missing balances produce warnings, not hard failures.

## Bank Template Strategy

Each bank template should define:

- Bank id.
- Country.
- Known statement labels.
- Date formats.
- Currency formats.
- Header patterns.
- Transaction row parsing patterns.
- Balance column rules.
- Parser version.

Templates should be data-driven where possible, but complex banks can use custom parser classes.

## OCR Position

OCR is not a first assumption. Digital PDFs should be parsed locally first. OCR should be used when:

- PDF has no extractable text.
- User uploads scanned images.
- Template parser cannot find transaction rows.

OCR providers to benchmark later:

- Google Document AI.
- Google Cloud Vision.
- On-device OCR options if accuracy is acceptable.

## Open Questions

- Which first 5-8 banks will be supported?
- Which PDF parsing package performs best on password-protected statements?
- Can all MVP parsing remain local for text PDFs?
- What minimum sample set is needed before claiming support for a bank?
