# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

ReconSnap Statement Converter turns bank-statement PDFs into accountant-ready CSV/XLSX. The repo is a two-part monorepo:

- `apps/mobile/` — the Flutter app (the product). Owns all parsing, debit/credit reconciliation, validation, and export.
- `apps/api/` — a thin, **stateless** FastAPI service that only extracts clean text from PDF bytes. It does no parsing.

The split is deliberate: the PDF leaves the device for text extraction (pdfplumber is too heavy to ship natively), but the meaning of that text — transactions, balances, confidence — is reconstructed entirely client-side. Keep it that way. Any caching/logging of statement content on the server, or moving parsing logic into the API, is a significant architectural change that needs a deliberate decision.

## Commands

Mobile (`cd apps/mobile`):
```bash
flutter pub get
flutter run --dart-define=RECONSNAP_API_BASE_URL=http://10.0.2.2:8000  # Android emulator → host
flutter test                                              # all tests
flutter test test/core/parsing/transaction_line_parser_test.dart   # single file
flutter test --name "reconciles debits"                   # single test by name
flutter analyze
dart format .
```
Note: Android emulators reach the host machine at `10.0.2.2`, not `localhost`. The API base URL is injected via `--dart-define=RECONSNAP_API_BASE_URL`; default is `http://localhost:8000` (see `lib/app/config/app_config.dart`).

API (`cd apps/api`):
```bash
python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt
uvicorn reconsnap_api.main:app --reload
python3 -m unittest discover -s tests        # pure normalisation logic, no deps needed
```

Run `dart format`, `flutter analyze`, and focused tests before delivering mobile changes.

## Architecture

### The conversion pipeline (mobile)

A conversion flows through clearly separated layers, each tested in isolation:

1. **`StatementTextExtractor`** (`core/parsing/text/`) — PDF bytes → clean text. The real impl `RemotePdfTextExtractor` calls the FastAPI `/extract` endpoint. Failures surface as **typed exceptions** (`PasswordRequiredException`, `OcrNotSupportedException`, `ExtractionException`) so the UI can react with recoverable states rather than a generic error.
2. **`TransactionLineParser`** (`core/parsing/text/transaction_line_parser.dart`) — text → reconciled transactions. This is the core IP. Once a PDF is flattened to text the debit/credit column structure is lost; the parser recovers it from the **running balance** (sign of `balance - previousBalance` decides debit vs credit, magnitude cross-checks the amount). That reconciliation also drives a **per-row confidence score** so low-confidence rows can be flagged for review — the trust feature the product is built around.
3. **`DigitalPdfStatementParser`** (`core/parsing/`) — thin wiring of extractor + line parser, plus country→currency mapping. Implements the `StatementParser` interface (`ParseInput` → `ParseResult`).
4. **`ValidationEngine`** (`core/validation/`) — checks balance reconciliation across the transaction set, producing a `ValidationReport`.
5. **`CsvExportService`** (`core/services/`) — `ParseResult` → CSV.

`MockStatementParser` is a second `StatementParser` impl behind the "Run demo conversion" affordance — it ignores bytes and returns canned data.

### State & navigation

- **Riverpod** is the DI/state container. `ConversionController` (`features/conversion/presentation/conversion_controller.dart`) is the orchestration hub: it holds `ConversionState`, runs both real and mock conversions, and translates the typed extractor exceptions into status values (`needsPassword`, `failed`, `ready`, …). It keeps `pendingBytes` so a password can be supplied and the conversion retried without re-picking the file.
- **go_router** (`app/router/app_router.dart`) defines flat named routes: `/`, `/upload`, `/processing`, `/validation`, `/history`, `/settings`.
- Providers (parsers, extractor, validator, exporter) are declared at the top of `conversion_controller.dart`.

### Layout

```
lib/
  app/        config (AppConfig dart-defines), theme (tokens + ReconSnapTheme), router, shared widgets
  core/       models, parsing (text pipeline), validation, services (export), formatting  ← no Flutter UI imports
  features/   conversion | history | settings, each with presentation/  ← UI only
```
Keep `core/` free of UI concerns. Keep parser logic isolated from UI, and export logic isolated from parser logic.

### API (`apps/api/reconsnap_api/`)

`main.py` (FastAPI app, `/health` + `/extract`) → `extraction.py` (pdfplumber + pikepdf for encrypted PDFs) → `normalize.py` (pure text cleanup, the only unit-tested part). Status codes are part of the contract: `422` = password required/incorrect (client prompts), `400` = unreadable, `413` = >25 MB. `needs_ocr: true` means no text layer (scanned PDF) — client shows "OCR not yet supported", not a generic failure.

## Constraints

- Do not copy GPL code from `research/open-source-references/` into the commercial app; document any third-party reference before reuse.
- The API must stay stateless — upload bytes live in memory for the request only, never on disk.
- Day-first date parsing is the default (`TransactionLineParser.dayFirst = true`) for UAE/GCC/UK; US statements need `dayFirst: false`.

## Docs

Product/architecture detail lives in `docs/`: `IMPLEMENTATION_PLAN.md`, `PARSER_ARCHITECTURE.md`, `UI_DESIGN_SYSTEM.md`, `ASO_STRATEGY.md`.
