# Open Source References

This folder is for reference projects, license notes, and implementation learnings. Code from these projects must not be copied into ReconSnap until the license and attribution requirements are reviewed.

## Usage Policy

- MIT and Apache-2.0 projects may be candidates for reuse with attribution.
- GPL projects are reference-only unless the app license strategy changes.
- No copied code should enter `apps/mobile` without documenting source, license, and reason.
- Prefer reimplementation in Dart/Flutter based on learned architecture.

## Reference Projects

| Project | Source | License status | Primary use | Reuse position |
|---|---|---|---|---|
| pdf-bank-statement-parser | https://github.com/J-sephB-lt-n/pdf-bank-statement-parser | GPL-3.0 | Bank-specific parsing and validation flow | Reference-only; do not copy code |
| pdf_statement_reader | https://github.com/marlanperumal/pdf_statement_reader | MIT | Config-driven parsing, password handling, validation ideas | Can inform implementation with attribution |
| bank-statement-converter | https://github.com/Anlanther/bank-statement-converter | MIT | Example parser flow and export shape | Can inform implementation with attribution |
| scb-statement-converter | https://github.com/shlomki/scb-statement-converter | Apache-2.0 | Local/password PDF conversion ideas | Can inform implementation with attribution |
| bank-statement-parser | https://github.com/felgru/bank-statement-parser | GPL-3.0-or-later plus CC0 license files | Parser architecture examples | Reference-only; do not copy code |
| ofxstatement-sample | https://github.com/kedder/ofxstatement-sample | GPLv3 classifier | Future OFX plugin model | Reference-only; do not copy code |
| open-design | https://github.com/nexu-io/open-design | Apache-2.0 | UI workflow and design-system inspiration | Can inform design workflow with attribution |

## First Study Questions

1. How does each parser identify transaction rows?
2. How are dates, debits, credits, and balances normalized?
3. How do they handle statement passwords?
4. Do they validate opening/closing balances?
5. What parts are reusable conceptually in Flutter?
6. What licenses prevent direct reuse?
