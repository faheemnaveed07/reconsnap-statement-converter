import 'package:flutter/material.dart';

import '../../../app/config/app_config.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/reconsnap_theme.dart';
import '../../../app/widgets/app_components.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const routeName = 'settings';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            const _ProfileCard(),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: 'Account'),
            const SizedBox(height: AppSpacing.md),
            const _SettingsTile(
              icon: Icons.credit_card_rounded,
              title: 'Credits and billing',
              subtitle: 'Page allowances and credit packs will live here.',
            ),
            const SizedBox(height: AppSpacing.md),
            const _SettingsTile(
              icon: Icons.lock_outline_rounded,
              title: 'Privacy',
              subtitle:
                  'Files are processed and not stored. No bank credentials are ever requested.',
            ),
            const SizedBox(height: AppSpacing.md),
            const _SettingsTile(
              icon: Icons.support_agent_rounded,
              title: 'Request bank support',
              subtitle: 'Tell us which bank to add next.',
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: 'About'),
            const SizedBox(height: AppSpacing.md),
            const _SettingsTile(
              icon: Icons.dns_rounded,
              title: 'Conversion service',
              subtitle: AppConfig.apiBaseUrl,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Row(
        children: [
          const BrandMark(size: 48),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Guest', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Sign in with email, Google, or Apple — coming soon.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const StatusPill(label: 'Preview', tone: PillTone.info),
        ],
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
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: ReconSnapColors.subtle,
              borderRadius: AppRadius.all(AppRadius.sm),
            ),
            child: Icon(icon, color: ReconSnapColors.ink700, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(
            Icons.chevron_right_rounded,
            color: ReconSnapColors.ink400,
          ),
        ],
      ),
    );
  }
}
