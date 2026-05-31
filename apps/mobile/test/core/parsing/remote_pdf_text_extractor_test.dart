import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reconsnap_statement_converter/core/parsing/remote_pdf_text_extractor.dart';
import 'package:reconsnap_statement_converter/core/parsing/text/statement_text_extractor.dart';

RemotePdfTextExtractor _extractorReturning(
  int status,
  String body, {
  void Function(http.BaseRequest request)? onRequest,
}) {
  final client = MockClient((request) async {
    onRequest?.call(request);
    return http.Response(body, status);
  });
  return RemotePdfTextExtractor(baseUrl: 'https://api.test', client: client);
}

void main() {
  group('RemotePdfTextExtractor', () {
    test('maps a 200 response to ExtractedText', () async {
      final extractor = _extractorReturning(
        200,
        jsonEncode({
          'full_text': '01/05/2026 Coffee 5.00 95.00',
          'pages': ['p1'],
          'num_pages': 1,
          'encrypted': false,
          'needs_ocr': false,
        }),
      );

      final result = await extractor.extract(
        bytes: [1, 2, 3],
        filename: 'statement.pdf',
      );

      expect(result.fullText, contains('Coffee'));
      expect(result.numPages, 1);
      expect(result.needsOcr, isFalse);
    });

    test('sends the password field and posts to /extract', () async {
      // MockClient materialises the multipart request into a plain Request,
      // so we assert against the encoded body rather than .fields.
      String? path;
      String? body;
      String? method;
      final extractor = _extractorReturning(
        200,
        jsonEncode({
          'full_text': 'x',
          'num_pages': 1,
          'encrypted': true,
          'needs_ocr': false,
        }),
        onRequest: (r) {
          path = r.url.path;
          method = r.method;
          if (r is http.Request) body = r.body;
        },
      );

      await extractor.extract(
        bytes: [1],
        filename: 's.pdf',
        password: 'secret',
      );

      expect(method, 'POST');
      expect(path, '/extract');
      expect(body, contains('name="password"'));
      expect(body, contains('secret'));
    });

    test('maps 422 to PasswordRequiredException with server detail', () async {
      final extractor = _extractorReturning(
        422,
        jsonEncode({'detail': 'Incorrect or missing PDF password.'}),
      );

      expect(
        () => extractor.extract(bytes: [1], filename: 's.pdf'),
        throwsA(isA<PasswordRequiredException>()),
      );
    });

    test('throws OcrNotSupportedException when needs_ocr is true', () async {
      final extractor = _extractorReturning(
        200,
        jsonEncode({
          'full_text': '',
          'num_pages': 3,
          'encrypted': false,
          'needs_ocr': true,
        }),
      );

      expect(
        () => extractor.extract(bytes: [1], filename: 's.pdf'),
        throwsA(isA<OcrNotSupportedException>()),
      );
    });

    test('maps other failures to ExtractionException', () async {
      final extractor = _extractorReturning(500, 'oops');
      expect(
        () => extractor.extract(bytes: [1], filename: 's.pdf'),
        throwsA(isA<ExtractionException>()),
      );
    });
  });
}
