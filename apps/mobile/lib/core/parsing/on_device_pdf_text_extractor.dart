import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'positioned/positioned_models.dart';
import 'positioned/positioned_pdf_extractor.dart';
import 'text/statement_text_extractor.dart';

/// Reads the PDF text layer entirely on-device, exposing both a flat-text view
/// ([StatementTextExtractor]) and a positioned view ([PositionedPdfExtractor]).
///
/// This is the default extractor: it needs no server, so a conversion works on
/// any phone with no network, and — importantly for a statement app — the PDF
/// never leaves the device. It only handles *digital* PDFs (those with a real
/// text layer); a scanned PDF yields no text and surfaces as
/// [OcrNotSupportedException] so the UI can say "OCR coming soon" instead of a
/// generic failure.
///
/// The same typed exceptions as [RemotePdfTextExtractor] are thrown so the
/// controller/UI is identical regardless of which extractor is wired in.
class OnDevicePdfTextExtractor
    implements StatementTextExtractor, PositionedPdfExtractor {
  const OnDevicePdfTextExtractor();

  @override
  Future<ExtractedText> extract({
    required List<int> bytes,
    required String filename,
    String? password,
  }) async {
    final document = _open(bytes, password);
    final bool encrypted;
    final int pageCount;
    final String fullText;
    try {
      encrypted = _isEncrypted(document, password);
      pageCount = document.pages.count;
      // layoutText preserves the column spacing of the original PDF, so a
      // transaction table stays row-per-line with its columns separated instead
      // of being flattened into one run-on string (which makes rows unparseable).
      fullText = PdfTextExtractor(document).extractText(layoutText: true);
    } finally {
      document.dispose();
    }

    // A digital PDF has a text layer; a scan extracts to (essentially) nothing.
    if (fullText.trim().isEmpty) {
      throw const OcrNotSupportedException();
    }

    return ExtractedText(
      fullText: fullText,
      numPages: pageCount,
      encrypted: encrypted,
      needsOcr: false,
    );
  }

  @override
  Future<ExtractedDocument> extractDocument({
    required List<int> bytes,
    required String filename,
    String? password,
  }) async {
    final document = _open(bytes, password);
    final bool encrypted;
    final int pageCount;
    final List<PositionedLine> lines;
    try {
      encrypted = _isEncrypted(document, password);
      pageCount = document.pages.count;
      lines = _toPositionedLines(PdfTextExtractor(document).extractTextLines());
    } finally {
      document.dispose();
    }

    if (lines.isEmpty) {
      throw const OcrNotSupportedException();
    }

    return ExtractedDocument(
      lines: lines,
      numPages: pageCount,
      encrypted: encrypted,
    );
  }

  PdfDocument _open(List<int> bytes, String? password) {
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    try {
      return (password != null && password.isNotEmpty)
          ? PdfDocument(inputBytes: data, password: password)
          : PdfDocument(inputBytes: data);
    } catch (error) {
      // Syncfusion throws when an encrypted PDF is opened without the right
      // password. Map that to the recoverable password flow; anything else is
      // an unreadable file.
      if (_looksLikePasswordIssue(error)) {
        throw const PasswordRequiredException();
      }
      throw const ExtractionException('The file could not be read as a PDF.');
    }
  }

  static List<PositionedLine> _toPositionedLines(List<TextLine> textLines) {
    final lines = <PositionedLine>[];
    for (final line in textLines) {
      final words = <PositionedWord>[];
      for (final word in line.wordCollection) {
        if (word.text.trim().isEmpty) continue;
        words.add(
          PositionedWord(
            text: word.text,
            left: word.bounds.left,
            top: word.bounds.top,
            right: word.bounds.right,
            bottom: word.bounds.bottom,
          ),
        );
      }
      if (words.isEmpty) continue;
      lines.add(PositionedLine(words: words, pageIndex: line.pageIndex));
    }
    return lines;
  }

  static bool _isEncrypted(PdfDocument document, String? password) {
    return document.security.userPassword.isNotEmpty ||
        (password != null && password.isNotEmpty);
  }

  static bool _looksLikePasswordIssue(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('password') || message.contains('encrypt');
  }
}
