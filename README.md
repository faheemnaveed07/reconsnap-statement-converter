# ReconSnap Statement Converter

ReconSnap Statement Converter is a Flutter-first fintech utility for converting bank statement PDFs and scans into accountant-ready CSV/XLSX files. The MVP focuses on mobile review, local-bank templates, password-protected PDF handling, editable extracted transactions, and balance validation before export.

## Product Positioning

Store-facing title: **ReconSnap Statement Converter**

Core promise: convert bank PDFs into accountant-ready files with validation, not generic AI extraction.

Initial launch wedge: UAE/GCC or a narrow UK/Canada pilot, with 5-8 supported banks rather than broad unsupported claims.

## MVP Scope

In scope for MVP:

- Flutter Android and iOS foundation.
- Auth-ready architecture with mocked auth until Firebase is wired.
- PDF upload flow.
- Bank selection and detection structure.
- Parser engine abstraction with bank-template support.
- Mock conversion flow and one real parser prototype when sample statements are available.
- Editable transaction preview.
- Balance validation report.
- CSV export first, XLSX next.
- Local conversion history model.
- Credits/subscription model design.
- Professional fintech UI with empty, loading, error, and low-confidence states.

Out of scope for MVP:

- Full web companion app.
- Universal support for every bank.
- Direct bank connections or credential storage.
- QBO/Xero direct sync.
- Public API.
- Enterprise SOC 2 positioning.

## Repository Structure

Planned top-level structure:

```text
apps/mobile/                         Flutter app
docs/                                product, architecture, ASO, and parser docs
research/open-source-references/     reference clones and license notes
```

## Documentation

- [Implementation Plan](docs/IMPLEMENTATION_PLAN.md)
- [UI Design System](docs/UI_DESIGN_SYSTEM.md)
- [Parser Architecture](docs/PARSER_ARCHITECTURE.md)
- [ASO Strategy](docs/ASO_STRATEGY.md)
- [Open Source References](research/open-source-references/README.md)

## Development Principles

- Keep the MVP narrow and shippable.
- Prefer accountant trust over flashy AI claims.
- Do not copy GPL code into the commercial app.
- Document third-party references before reuse.
- Keep parser logic isolated from UI.
- Keep export logic isolated from parser logic.
- Run `dart format`, `flutter analyze`, and focused tests before delivery.
