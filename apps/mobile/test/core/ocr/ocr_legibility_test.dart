import 'package:flutter_test/flutter_test.dart';
import 'package:reconsnap_statement_converter/core/ocr/ocr_legibility.dart';
import 'package:reconsnap_statement_converter/core/ocr/ocr_models.dart';

OcrResult _result(int wordCount, {double? confidence}) {
  return OcrResult([
    OcrLine([
      for (var i = 0; i < wordCount; i++)
        OcrWord(
          text: 'w$i',
          left: 0,
          top: 0,
          right: 10,
          bottom: 10,
          confidence: confidence,
        ),
    ]),
  ]);
}

void main() {
  group('assessLegibility', () {
    test('too little recovered text is poor regardless of confidence', () {
      final a = assessLegibility([_result(5, confidence: 0.99)]);
      expect(a.level, ScanLegibility.poor);
    });

    test('high mean confidence reads as good', () {
      final a = assessLegibility([_result(40, confidence: 0.92)]);
      expect(a.level, ScanLegibility.good);
      expect(a.meanConfidence, closeTo(0.92, 0.001));
    });

    test('mid confidence reads as fair', () {
      final a = assessLegibility([_result(40, confidence: 0.65)]);
      expect(a.level, ScanLegibility.fair);
    });

    test('low confidence reads as poor', () {
      final a = assessLegibility([_result(40, confidence: 0.40)]);
      expect(a.level, ScanLegibility.poor);
      expect(a.isPoor, isTrue);
    });

    test(
      'no confidence data with enough text is unknown (null), never faked',
      () {
        final a = assessLegibility([_result(40)]);
        expect(a.level, isNull);
        expect(a.wordCount, 40);
      },
    );

    test('aggregates across pages', () {
      final a = assessLegibility([
        _result(20, confidence: 0.9),
        _result(20, confidence: 0.9),
      ]);
      expect(a.wordCount, 40);
      expect(a.level, ScanLegibility.good);
    });
  });
}
