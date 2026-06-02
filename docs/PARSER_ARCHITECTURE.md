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

## Implemented (v2): column-aware templates

The generic line parser guessed debit/credit from balance deltas on flattened
text. That fails on real statements: separate Debit/Credit columns, reverse
chronological order, multi-line descriptions, and card numbers that look like
amounts. The v2 pipeline parses by **word position** instead.

Pipeline (all on-device), in `lib/core/parsing/`:

1. **Positioned extraction** — `OnDevicePdfTextExtractor.extractDocument()` uses
   Syncfusion `extractTextLines()` to return `ExtractedDocument`: lines of
   `PositionedWord`s, each with its bounding box (`positioned/`).
2. **Document classification** — `DocumentClassifier` (`classification/`) labels
   the file `accountStatement` / `annualReport` / `form` / `unreadable` /
   `unknown`. Only statements (and `unknown`) proceed; the rest are rejected
   with a clear reason via `UnsupportedDocumentException` rather than emitting
   junk rows.
3. **Bank detection** — `BankTemplateRegistry` (`templates/`) picks the
   highest-scoring `BankStatementTemplate` by header/footer fingerprint, nudged
   by the user's selected bank.
4. **Column-aware parse** — `ColumnLayout` (`column/`) finds the table header
   and builds X-position bands from the header words; `ColumnStatementParser`
   reads each row's cells by band. Debit/Credit come from their own columns
   (so description numbers are ignored), multi-line descriptions are stitched,
   reverse order is normalised by balance-continuity, and the running balance
   only *validates* (flags low-confidence rows) — it never silently rewrites a
   value. No template match → generic `TransactionLineParser` fallback.

Orchestrated by `TemplatedStatementParser` (implements `StatementParser`).

### Adding a bank

Most banks are data, not code: add a `BankStatementTemplate` whose `parse()`
delegates to `ColumnStatementParser` with a `ColumnTableConfig` (column keyword
synonyms, `dayFirst`, footer markers) and a fingerprint in `matchScore()`, then
register it in `BankTemplateRegistry.defaultTemplates`. Only genuinely unusual
layouts need bespoke code. See `EmiratesNbdTemplate` for the reference.

OCR for scanned / broken-font PDFs is the next phase; `unreadable` and the
`OcrNotSupportedException` path are the hooks where it will plug in.
