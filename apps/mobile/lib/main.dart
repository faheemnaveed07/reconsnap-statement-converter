import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router/app_router.dart';
import 'app/theme/reconsnap_theme.dart';
import 'core/services/first_run_store.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Resolve onboarding state before the first frame so the initial route is
  // correct with no flash of the wrong screen.
  final seenOnboarding = await FirstRunStore().isSeen();
  runApp(
    ProviderScope(
      overrides: [onboardingSeenProvider.overrideWithValue(seenOnboarding)],
      child: const ReconSnapApp(),
    ),
  );
}

class ReconSnapApp extends ConsumerWidget {
  const ReconSnapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ReconSnap Statement Converter',
      debugShowCheckedModeBanner: false,
      theme: ReconSnapTheme.light,
      routerConfig: router,
    );
  }
}
