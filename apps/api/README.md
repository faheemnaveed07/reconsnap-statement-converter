# ReconSnap Extraction API

A thin, stateless FastAPI service that turns an uploaded bank-statement PDF into
clean text. **All transaction parsing, debit/credit reconciliation, and balance
validation live in the Flutter client** (`TransactionLineParser`) — this service
only extracts and normalises text.

## Why server-side extraction

pdfplumber gives strong text/table extraction across many statement layouts
without shipping a large native PDF engine inside the mobile app. The trade-off
is that the PDF leaves the device, so the client must clearly tell users that
processing happens on the server, and the privacy policy must state that
uploads are processed in memory and never stored.

## Endpoints

| Method | Path       | Purpose                                   |
| ------ | ---------- | ----------------------------------------- |
| GET    | `/health`  | Liveness probe                            |
| POST   | `/extract` | Multipart PDF upload → cleaned text + meta |

`POST /extract` form fields:

- `file` (required): the PDF.
- `password` (optional): for password-protected PDFs.

Response:

```json
{
  "full_text": "01/05/2026 ...",
  "pages": ["page 1 text", "page 2 text"],
  "num_pages": 2,
  "encrypted": false,
  "needs_ocr": false
}
```

`needs_ocr: true` means no text layer was found (likely a scanned PDF) — the
client should surface an "OCR not yet supported" message rather than a generic
failure.

Status codes: `422` = password required/incorrect (client can prompt),
`400` = unreadable PDF, `413` = file too large (>25 MB).

## Run locally

```bash
cd apps/api
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn reconsnap_api.main:app --reload
```

## Tests

The pure normalisation logic is tested with stdlib `unittest` (no install
needed):

```bash
cd apps/api
python3 -m unittest discover -s tests
```

## Privacy

The service holds upload bytes in memory only for the duration of the request
and never writes them to disk. Keep it that way: any future caching/logging of
statement content must be a deliberate, documented decision.
