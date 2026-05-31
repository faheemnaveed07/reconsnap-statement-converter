# UI Design System

## Product Feel

ReconSnap should feel like a premium fintech utility: quiet, focused, and accurate. The UI must help users trust the conversion result, not distract them with decorative effects.

Reference qualities:

- Stripe: clean business polish.
- Linear: tight spacing and elegant interaction states.
- Cash App: confident mobile simplicity.
- Open Design: structured design-system inspiration and workflow support.

## Palette

Primary ink: `#102033`

Surface: `#F7F9FB`

Card: `#FFFFFF`

Border: `#DCE3EA`

Muted text: `#667085`

Accent green: `#0E9F6E`

Action blue: `#2563EB`

Warning amber: `#B7791F`

Risk red: `#D92D20`

## Typography

Use system fonts:

- iOS: SF Pro
- Android: Roboto
- Web fallback: Inter/system sans

Text hierarchy:

- Display: 28-32, semibold
- Page title: 22-24, semibold
- Section title: 16-18, semibold
- Body: 14-16, regular
- Metadata: 12-13, medium/regular

## Core Screens

### Home

Purpose: start conversion quickly and show recent work.

Required states:

- No history empty state.
- Recent conversions.
- Remaining credits.
- Primary "Convert statement" action.

### Upload Statement

Purpose: accept PDF/scanned statement with minimal friction.

Required states:

- Browse files.
- Take photo/scan later.
- Password prompt if protected.
- Unsupported file error.

### Bank Select/Detect

Purpose: make bank-template matching transparent.

Required states:

- Auto-detected bank.
- Manual bank selection.
- Unsupported bank request.

### Processing

Purpose: reassure users during extraction.

Required states:

- Local parsing.
- Cloud OCR fallback later.
- Error with retry.

### Preview/Edit

Purpose: let accountants verify extracted rows.

Required states:

- Transaction table/list.
- Low-confidence row state.
- Edit row.
- Delete/restore row.

### Validation Report

Purpose: prove the output is trustworthy.

Required states:

- Pass.
- Warning.
- Failed validation.
- Missing opening/closing balance.

### Export

Purpose: generate output without confusion.

Required states:

- CSV available.
- XLSX next.
- QBO/Xero locked for future/pro.

## Component Standards

- Use icons for actions where obvious.
- Use cards only for functional grouped surfaces.
- Avoid nested cards.
- Keep buttons stable in size.
- Make error messages specific and recoverable.
- Make all important actions reachable within three taps.

## Screenshot/ASO Captions

1. Bank Statement to Excel
2. Upload PDF or Scanned Statement
3. Review and Fix Extracted Rows
4. Balance Check Before Export
5. Built for Accountants and SMEs
