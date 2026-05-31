import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reconsnap_statement_converter/main.dart';

void main() {
  testWidgets('shows ReconSnap home experience', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ReconSnapApp()));

    expect(find.text('Bank PDFs to accountant-ready files'), findsOneWidget);
    expect(find.text('Convert statement'), findsOneWidget);
  });
}
