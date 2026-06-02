import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'text/statement_text_extractor.dart';

/// [StatementTextExtractor] that reads the PDF text layer entirely on-device.
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
class OnDevicePdfTextExtractor implements StatementTextExtractor {
  const OnDevicePdfTextExtractor();

  @override
  Future<ExtractedText> extract({
    required List<int> bytes,
    required String filename,
    String? password,
  }) async {
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);

    PdfDocument document;
    try {
      document = (password != null && password.isNotEmpty)
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

    final bool encrypted;
    final int pageCount;
    final String fullText;
    try {
      encrypted =
          document.security.userPassword.isNotEmpty ||
          (password != null && password.isNotEmpty);
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

  static bool _looksLikePasswordIssue(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('password') || message.contains('encrypt');
  }
}
