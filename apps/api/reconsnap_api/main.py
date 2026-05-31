"""FastAPI entrypoint for the ReconSnap extraction service.

Endpoints:
  GET  /health   -> liveness probe
  POST /extract  -> multipart PDF upload -> cleaned text + metadata

Privacy posture: the service is stateless. Uploaded bytes are held only in
memory for the duration of the request and never written to disk. The client
is responsible for telling the user that processing happens server-side.
"""

from __future__ import annotations

from fastapi import FastAPI, File, Form, HTTPException, UploadFile

from . import __version__
from .extraction import (
    ExtractionError,
    PasswordRequired,
    extract_pdf,
)

app = FastAPI(title="ReconSnap Extraction API", version=__version__)

# Reject absurdly large uploads early (statements are small; 25 MB is generous).
MAX_BYTES = 25 * 1024 * 1024


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "version": __version__}


@app.post("/extract")
async def extract(
    file: UploadFile = File(...),
    password: str | None = Form(default=None),
) -> dict:
    data = await file.read()
    if not data:
        raise HTTPException(status_code=400, detail="Empty file.")
    if len(data) > MAX_BYTES:
        raise HTTPException(status_code=413, detail="File too large (max 25 MB).")

    try:
        result = extract_pdf(data, password=password)
    except PasswordRequired as exc:
        # 422 so the client can prompt for a password without treating it as a
        # hard failure.
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    except ExtractionError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return {
        "full_text": result.full_text,
        "pages": result.pages,
        "num_pages": result.num_pages,
        "encrypted": result.encrypted,
        "needs_ocr": result.needs_ocr,
    }
