import 'package:flutter/material.dart';

import '../../../app/theme/reconsnap_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const routeName = 'settings';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            _SettingsTile(
              icon: Icons.person_outline_rounded,
              title: 'Profile',
              subtitle:
                  'Auth-ready placeholder for email, Google, and Apple login.',
            ),
            SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.credit_card_rounded,
              title: 'Credits and billing',
              subtitle: 'Page allowances and credit packs will live here.',
            ),
            SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.lock_outline_rounded,
              title: 'Privacy',
              subtitle:
                  'No bank credentials. Temporary cloud files only when required.',
            ),
            SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.support_agent_rounded,
              title: 'Request bank support',
              subtitle:
                  'Collect unsupported-bank demand and sample consent later.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: ReconSnapColors.ink),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
