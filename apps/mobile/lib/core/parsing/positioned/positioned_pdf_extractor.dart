import 'positioned_models.dart';

/// Extracts a PDF into positioned lines/words so a bank template can recover
/// column structure from word coordinates.
///
/// Implementations throw the same typed exceptions as [StatementTextExtractor]
/// (`PasswordRequiredException`, `OcrNotSupportedException`,
/// `ExtractionException`) so the controller/UI reacts identically regardless of
/// which extraction path is used.
abstract interface class PositionedPdfExtractor {
  Future<ExtractedDocument> extractDocument({
    required List<int> bytes,
    required String filename,
    String? password,
  });
}
