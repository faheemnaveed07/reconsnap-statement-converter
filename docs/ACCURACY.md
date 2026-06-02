# Accuracy: measuring before claiming

ReconSnap's entire positioning is *trust* — "every row is correct, or flagged
for review, never silently wrong." That promise is only credible with a
**measured** accuracy number on **real** statements. This harness produces that
number and guards it against regressions as new bank templates are added.

Until a real number exists, we claim nothing.

## The metric that matters: silent errors

For a converter an accountant relies on, the worst outcome is not a missed row —
it's a **wrong row presented as correct**. The harness's headline number is
therefore **silent errors**: rows that are wrong on direction, balance, or
description *yet* were given high confidence (≥ review threshold). The gate is
**silent errors must be 0**. Recall and field accuracy are reported too, but a
flagged-for-review row is an acceptable outcome; a confident wrong row is not.

## Data collection playbook (this is the bottleneck — only you can do it)

What to collect, in priority order:

1. **Emirates NBD** retail/business account statement (validate the existing
   template first).
2. Then **FAB, ADCB, Mashreq, Dubai Islamic Bank** — 2–3 statements each.

Requirements per statement:

- **Digitally generated PDF** ("Download as PDF" from online banking), *not* a
  phone photo or scan (those need the OCR phase).
- **Anonymised**: black out account number, name, address. **Keep the whole
  transaction table intact** — dates, descriptions, debit/credit columns,
  balance column, and the printed opening/closing balances.
- A **full month** with many rows is more useful than a sparse one.
- Variety helps: at least one with separate Debit/Credit columns, one with
  multi-line descriptions, one password-protected.

Minimum to claim a bank "supported": **3 statements, silent errors = 0,
recall ≥ 98%.**

## Adding a fixture

Put the pair in `apps/mobile/test/fixtures/accuracy/` (git-ignored — never
committed):

```
test/fixtures/accuracy/enbd-2024-06.pdf
test/fixtures/accuracy/enbd-2024-06.expected.json
```

Ground-truth JSON (hand-verified from the PDF):

```json
{
  "bankId": "ae_emirates_nbd",
  "currency": "AED",
  "openingBalance": 5000.00,
  "closingBalance": 9916.34,
  "transactions": [
    { "date": "2024-06-01", "credit": 3000.00, "balance": 8000.00, "description": "Salary credit" },
    { "date": "2024-06-03", "debit": 200.00, "balance": 7800.00, "description": "Card Lulu" }
  ]
}
```

- `date` is ISO `YYYY-MM-DD`. Use `debit` **or** `credit` per row (omit/null the
  other). `balance` and `description` are optional but improve the score detail.

## Running

```bash
cd apps/mobile
flutter test test/accuracy/run_accuracy_harness_test.dart
```

With no fixtures it **skips** (safe for CI). With fixtures it prints a per-file
report and an aggregate, and **fails if any silent error exists**.

Reading a report line:

```
── enbd-2024-06.pdf (ae_emirates_nbd-v1)
   rows: expected=42 actual=42 matched=42 extra=0 missing=0
   recall=100.0% direction=100.0% balance=100.0%
   reviewBurden=4.8% flagged=2
   closingReconciled=true
   >>> SILENT ERRORS (wrong + unflagged) = 0
```

`reviewBurden` is the share of rows the user is asked to check — lower is better,
but only after silent errors are 0. The comparator's own math is unit-tested in
`test/accuracy/accuracy_metrics_test.dart`.
