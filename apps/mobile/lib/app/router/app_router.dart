import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/conversion/presentation/home_screen.dart';
import '../../features/conversion/presentation/processing_screen.dart';
import '../../features/conversion/presentation/upload_screen.dart';
import '../../features/conversion/presentation/validation_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: HomeScreen.routeName,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/upload',
        name: UploadScreen.routeName,
        builder: (context, state) => const UploadScreen(),
      ),
      GoRoute(
        path: '/processing',
        name: ProcessingScreen.routeName,
        builder: (context, state) => const ProcessingScreen(),
      ),
      GoRoute(
        path: '/validation',
        name: ValidationScreen.routeName,
        builder: (context, state) => const ValidationScreen(),
      ),
      GoRoute(
        path: '/history',
        name: HistoryScreen.routeName,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: SettingsScreen.routeName,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
