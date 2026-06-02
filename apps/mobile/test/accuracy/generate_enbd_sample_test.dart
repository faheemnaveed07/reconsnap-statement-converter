import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'enbd_sample_layout.dart';

/// Materialises the synthetic Emirates NBD fixture into the (git-ignored)
/// accuracy fixtures dir so the harness can run it and you can open the PDF.
///
///   GENERATE_FIXTURES=1 flutter test test/accuracy/generate_enbd_sample_test.dart
///   flutter test test/accuracy/run_accuracy_harness_test.dart
///
/// Guarded by an env flag so the normal test suite never writes files. Replace
/// these with a *real* Emirates NBD statement + hand-checked JSON when you have
/// one — same filenames, and the harness measures it the same way.
void main() {
  test('write enbd-sample fixture (GENERATE_FIXTURES=1)', () {
    if (Platform.environment['GENERATE_FIXTURES'] != '1') {
      markTestSkipped('Set GENERATE_FIXTURES=1 to write the fixture.');
      return;
    }
    final dir = Directory('test/fixtures/accuracy')
      ..createSync(recursive: true);
    File('${dir.path}/enbd-sample.pdf').writeAsBytesSync(buildEnbdSamplePdf());
    File(
      '${dir.path}/enbd-sample.expected.json',
    ).writeAsStringSync(enbdSampleGroundTruthJson());
    stderr.writeln('Wrote ${dir.path}/enbd-sample.pdf + .expected.json');
  });
}
