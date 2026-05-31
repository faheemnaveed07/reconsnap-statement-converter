/// Result of turning a PDF into text. Mirrors the backend `/extract` response.
class ExtractedText {
  const ExtractedText({
    required this.fullText,
    required this.numPages,
    required this.encrypted,
    required this.needsOcr,
  });

  final String fullText;
  final int numPages;
  final bool encrypted;

  /// True when the PDF had no text layer (likely scanned) — OCR not yet
  /// supported, so the UI should say so rather than show a generic error.
  final bool needsOcr;
}

/// Thrown when the PDF is encrypted and the password is missing/incorrect.
/// The UI catches this to prompt the user for a password.
class PasswordRequiredException implements Exception {
  const PasswordRequiredException([this.message = 'Password required.']);
  final String message;
  @override
  String toString() => 'PasswordRequiredException: $message';
}

/// Thrown when the document has no extractable text (scanned PDF).
class OcrNotSupportedException implements Exception {
  const OcrNotSupportedException([
    this.message = 'This looks like a scanned statement. OCR is coming soon.',
  ]);
  final String message;
  @override
  String toString() => 'OcrNotSupportedException: $message';
}

/// Thrown for any other extraction failure (unreadable file, network, server).
class ExtractionException implements Exception {
  const ExtractionException(this.message);
  final String message;
  @override
  String toString() => 'ExtractionException: $message';
}

/// Turns raw PDF bytes into clean text. Implementations may run on-device or
/// call a backend; the rest of the app depends only on this interface.
abstract interface class StatementTextExtractor {
  Future<ExtractedText> extract({
    required List<int> bytes,
    required String filename,
    String? password,
  });
}
