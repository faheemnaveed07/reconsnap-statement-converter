import 'package:flutter/material.dart';

import '../../features/conversion/presentation/home_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../theme/reconsnap_theme.dart';

/// The app's spine — three persistent destinations. Convert is the start surface
/// and the linear conversion sub-flow (Source → Processing → Result) pushes on
/// top of it; History and Account are always one tap away from anywhere. Each
/// destination keeps its own AppBar; the shell only owns the bottom bar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static const routeName = 'shell';

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [HomeScreen(), HistoryScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: ReconSnapColors.paper,
        indicatorColor: ReconSnapColors.accentSurface,
        surfaceTintColor: Colors.transparent,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.swap_horiz_rounded),
            label: 'Convert',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
