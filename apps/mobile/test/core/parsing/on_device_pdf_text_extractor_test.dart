import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:reconsnap_statement_converter/core/parsing/on_device_pdf_text_extractor.dart';
import 'package:reconsnap_statement_converter/core/parsing/text/statement_text_extractor.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Builds a single-page PDF whose text layer is [text]. Syncfusion's PDF
/// creation + extraction are pure Dart, so this runs without a device.
List<int> _pdfWithText(String text, {String? userPassword}) {
  final document = PdfDocument();
  if (userPassword != null) {
    document.security.userPassword = userPassword;
  }
  final page = document.pages.add();
  page.graphics.drawString(
    text,
    PdfStandardFont(PdfFontFamily.courier, 12),
    bounds: const Rect.fromLTWH(0, 0, 500, 700),
  );
  final bytes = document.saveSync();
  document.dispose();
  return bytes;
}

void main() {
  const extractor = OnDevicePdfTextExtractor();

  test('extracts the text layer from a digital PDF', () async {
    final bytes = _pdfWithText('01/05/2026 Opening Balance 5,000.00');

    final result = await extractor.extract(
      bytes: bytes,
      filename: 'statement.pdf',
    );

    expect(result.fullText, contains('Opening Balance'));
    expect(result.fullText, contains('5,000.00'));
    expect(result.numPages, 1);
    expect(result.needsOcr, isFalse);
  });

  test(
    'opens a password-protected PDF when the password is supplied',
    () async {
      final bytes = _pdfWithText(
        'Salary credit 3,500.00',
        userPassword: 'secret',
      );

      final result = await extractor.extract(
        bytes: bytes,
        filename: 'locked.pdf',
        password: 'secret',
      );

      expect(result.fullText, contains('Salary credit'));
      expect(result.encrypted, isTrue);
    },
  );

  test('throws PasswordRequiredException without the password', () async {
    final bytes = _pdfWithText(
      'Salary credit 3,500.00',
      userPassword: 'secret',
    );

    expect(
      () => extractor.extract(bytes: bytes, filename: 'locked.pdf'),
      throwsA(isA<PasswordRequiredException>()),
    );
  });

  test('throws ExtractionException for non-PDF bytes', () async {
    expect(
      () => extractor.extract(bytes: const [1, 2, 3, 4], filename: 'not-a.pdf'),
      throwsA(isA<ExtractionException>()),
    );
  });
}
