# Implementation Plan

## Baseline Inspection Summary

The GitHub repository was cloned successfully and is currently empty. There is no Flutter scaffold, no existing source code, and no prior project structure to preserve. The attached refined SRS is the source of truth for product scope and positioning.

Key SRS decisions:

- Use ReconSnap as the product brand.
- Use "ReconSnap Statement Converter" as the store-facing title.
- Start with a focused mobile MVP.
- Avoid broad unsupported claims such as "1000+ banks".
- Prioritize bank-template accuracy, editable preview, and balance validation.
- Treat UAE/GCC as the strongest launch wedge, with UK/Canada as a practical alternative.

## Recommended Folder Structure

```text
.
├── apps/
│   └── mobile/
│       ├── lib/
│       │   ├── app/
│       │   ├── core/
│       │   ├── features/
│       │   │   ├── auth/
│       │   │   ├── banks/
│       │   │   ├── conversion/
│       │   │   ├── exports/
│       │   │   ├── history/
│       │   │   ├── settings/
│       │   │   └── subscription/
│       │   └── shared/
│       └── test/
├── docs/
└── research/
    └── open-source-references/
```

## First 10 GitHub Issues

1. Scaffold Flutter app under `apps/mobile`.
2. Add Riverpod, go_router, file picker, CSV/export, and test dependencies.
3. Build the ReconSnap theme and design tokens.
4. Implement navigation shell for Home, Upload, Preview, Validation, History, and Settings.
5. Define domain models: Bank, StatementTransaction, ConversionJob, ValidationReport, SubscriptionPlan.
6. Create parser engine interfaces and mock parser implementation.
7. Build mock conversion flow from upload to preview.
8. Implement balance validation logic and tests.
9. Implement CSV export and tests.
10. Create open-source reference notes with license status and reusable ideas.

## 30-Day Plan

### Week 1: Foundation

- Finalize repo structure.
- Scaffold Flutter app.
- Add dependencies and linting.
- Implement theme, typography, color tokens, and app shell.
- Create static screens for the core flow.

Exit criteria:

- App launches locally.
- Navigation works across core screens.
- Design system feels professional, not default Flutter.

### Week 2: Domain and Mock Flow

- Add core domain models.
- Add parser interfaces.
- Add mock parser with realistic transaction data.
- Add conversion state machine.
- Build upload, processing, preview, and validation states.

Exit criteria:

- User can complete a mock conversion flow.
- Validation report is generated from extracted transactions.

### Week 3: Exports and Local Persistence

- Implement CSV export.
- Add conversion history model.
- Add local persistence adapter.
- Add tests for validation and export formatting.

Exit criteria:

- User can export a CSV from the mock conversion.
- Validation/export logic has tests.

### Week 4: Parser Prototype and Beta Readiness

- Study selected open-source references.
- Prototype one bank-template parser using sample statements when available.
- Document failure states and unsupported-bank request flow.
- Polish UI states and paywall/credits model.

Exit criteria:

- MVP can demo a believable conversion workflow.
- Parser architecture is ready for real bank templates.

## UI Design Direction

ReconSnap should feel like a polished fintech/productivity app: calm, precise, trustworthy, and fast. It should not look like a template app or an AI toy.

Design traits:

- Deep ink/navy base with fresh green success accents.
- High whitespace, clear cards, strong section labels.
- Data tables optimized for review and correction.
- Professional iconography.
- Clear validation language.
- No exaggerated gradients or decorative clutter.

Primary flow:

Home -> Upload Statement -> Select/Detect Bank -> Processing -> Preview/Edit -> Validation Report -> Export

## Parser Implementation Strategy

Use a layered parser architecture:

1. File intake: file metadata, password handling, PDF type detection.
2. Text extraction: digital PDF extraction where possible.
3. Bank detection: fingerprints, known labels, layout hints, user-selected fallback.
4. Template parser: bank-specific parsing rules.
5. Normalization: date, description, debit, credit, amount, balance.
6. Validation: opening/closing balance, totals, date ordering, duplicate detection.
7. Export mapping: CSV first, XLSX next, QBO/Xero later.

## Open Source Study Priority

Study first:

1. `pdf_statement_reader` for config-driven parsing and validation ideas.
2. `scb-statement-converter` for password/local browser conversion concepts.
3. `pdf-bank-statement-parser` for transaction validation and bank-specific parsing flow.
4. `ofxstatement-sample` for future OFX/export plugin concepts.
5. `open-design` for UI system inspiration and design workflow.

Use these as references unless licenses and attribution allow reuse.
