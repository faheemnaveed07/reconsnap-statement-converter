import '../parsing/positioned/positioned_models.dart';
import 'ocr_legibility.dart';
import 'ocr_models.dart';
import 'ocr_recognizer.dart';

/// An OCR'd document together with how legible the scan was — so the UI can warn
/// on a poor scan *before* parsing, and show the reading as an honest trust
/// signal on the result.
class OcrExtraction {
  const OcrExtraction({required this.document, required this.legibility});
  final ExtractedDocument document;
  final LegibilityAssessment legibility;
}

/// Turns an image (photo or scan) into the same [ExtractedDocument] of
/// positioned words that the digital-PDF extractor produces — so the document
/// classifier, bank templates, and balance reconciliation all apply unchanged.
class OcrDocumentExtractor {
  const OcrDocumentExtractor(this._recognizer);

  final OcrRecognizer _recognizer;

  Future<OcrExtraction> extract(String imagePath) async {
    final result = await _recognizer.recognizeFile(imagePath);
    final doc = toDocument(result);
    if (doc.lines.isEmpty) throw const OcrFailedException();
    return OcrExtraction(document: doc, legibility: assessLegibility([result]));
  }

  /// OCRs several page images (a rasterised scanned PDF) into one document,
  /// preserving page order so multi-page templates still reconcile.
  Future<OcrExtraction> extractMany(List<String> imagePaths) async {
    final results = <OcrResult>[];
    for (final path in imagePaths) {
      results.add(await _recognizer.recognizeFile(path));
    }
    final doc = toDocumentFromPages(results);
    if (doc.lines.isEmpty) throw const OcrFailedException();
    return OcrExtraction(document: doc, legibility: assessLegibility(results));
  }

  /// Pure mapping from a single-page OCR result to a positioned document.
  static ExtractedDocument toDocument(OcrResult result) =>
      toDocumentFromPages([result]);

  /// Pure mapping from multiple OCR pages. Word boxes become positioned words;
  /// the X positions are what let column detection work, and page order is kept.
  static ExtractedDocument toDocumentFromPages(List<OcrResult> pages) {
    final lines = <PositionedLine>[];
    for (var page = 0; page < pages.length; page++) {
      for (final line in pages[page].lines) {
        final words = <PositionedWord>[];
        for (final w in line.words) {
          if (w.text.trim().isEmpty) continue;
          words.add(
            PositionedWord(
              text: w.text,
              left: w.left,
              top: w.top,
              right: w.right,
              bottom: w.bottom,
            ),
          );
        }
        if (words.isNotEmpty) {
          lines.add(PositionedLine(words: words, pageIndex: page));
        }
      }
    }
    return ExtractedDocument(
      lines: lines,
      numPages: pages.isEmpty ? 1 : pages.length,
      encrypted: false,
    );
  }
}
