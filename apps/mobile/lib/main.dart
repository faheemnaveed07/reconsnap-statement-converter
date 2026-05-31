import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router/app_router.dart';
import 'app/theme/reconsnap_theme.dart';

void main() {
  runApp(const ProviderScope(child: ReconSnapApp()));
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
