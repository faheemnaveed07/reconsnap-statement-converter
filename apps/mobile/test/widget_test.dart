import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reconsnap_statement_converter/features/onboarding/presentation/onboarding_screen.dart';
import 'package:reconsnap_statement_converter/main.dart';

void main() {
  testWidgets('shows ReconSnap home experience', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // Skip first-run onboarding to test the home experience directly.
        overrides: [onboardingSeenProvider.overrideWithValue(true)],
        child: const ReconSnapApp(),
      ),
    );

    expect(find.text('Bank PDFs to accountant-ready files'), findsOneWidget);
    expect(find.text('Convert statement'), findsOneWidget);
  });

  testWidgets('shows onboarding on first run', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [onboardingSeenProvider.overrideWithValue(false)],
        child: const ReconSnapApp(),
      ),
    );

    expect(find.text('Get started'), findsNothing); // not on the first slide
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Private by design'), findsNothing); // second slide
  });
}
