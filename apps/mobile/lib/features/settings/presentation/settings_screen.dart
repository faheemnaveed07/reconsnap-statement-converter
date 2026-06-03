import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/reconsnap_theme.dart';
import '../../../app/widgets/app_components.dart';
import '../../../core/services/review_prompter.dart';
import '../../billing/presentation/entitlements_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const routeName = 'settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlements = ref.watch(entitlementsProvider);

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
            _SettingsTile(
              icon: Icons.bolt_rounded,
              title: 'Credits and billing',
              subtitle: entitlements.isPro
                  ? 'Pro — unlimited conversions'
                  : '${entitlements.availableCredits} conversions remaining · tap to upgrade',
              onTap: () => context.pushNamed('paywall'),
            ),
            const SizedBox(height: AppSpacing.md),
            const _SettingsTile(
              icon: Icons.lock_outline_rounded,
              title: 'Privacy',
              subtitle:
                  'Statements are processed on your device and never uploaded. No bank credentials are ever requested.',
            ),
            const SizedBox(height: AppSpacing.md),
            const _SettingsTile(
              icon: Icons.support_agent_rounded,
              title: 'Request bank support',
              subtitle: 'Tell us which bank to add next.',
            ),
            const SizedBox(height: AppSpacing.md),
            _SettingsTile(
              icon: Icons.ios_share_rounded,
              title: 'Share ReconSnap',
              subtitle: 'Tell a colleague who drowns in manual data entry.',
              onTap: () => SharePlus.instance.share(
                ShareParams(
                  text:
                      'Convert bank statement PDFs to Excel/CSV/QuickBooks with '
                      'ReconSnap — on-device and balance-validated. $appShareUrl',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: 'About'),
            const SizedBox(height: AppSpacing.md),
            const _SettingsTile(
              icon: Icons.shield_outlined,
              title: 'Processing',
              subtitle: 'On your device — works offline, nothing uploaded.',
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
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
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
