import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/reconsnap_theme.dart';
import '../../../app/widgets/app_components.dart';
import '../../../core/models/bank.dart';
import '../../../core/services/review_prompter.dart';
import '../../billing/presentation/entitlements_controller.dart';

/// App version, mirrored from pubspec. Update on release.
const _appVersion = '1.0.0';

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
            _SettingsTile(
              icon: Icons.account_balance_rounded,
              title: 'Supported banks',
              subtitle: 'See which banks have a validated template.',
              onTap: () => _showSupportedBanks(context),
            ),
            const SizedBox(height: AppSpacing.md),
            _SettingsTile(
              icon: Icons.support_agent_rounded,
              title: 'Request bank support',
              subtitle: 'Tell us which bank to add next.',
              onTap: () => SharePlus.instance.share(
                ShareParams(
                  subject: 'ReconSnap — bank support request',
                  text:
                      'Please add ReconSnap support for my bank:\n\nBank name: \n'
                      'Country: \n\n(Sent from ReconSnap v$_appVersion)',
                ),
              ),
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
            const SizedBox(height: AppSpacing.md),
            _SettingsTile(
              icon: Icons.insights_rounded,
              title: 'Diagnostics',
              subtitle:
                  'Conversion outcomes (no statement content) you can share.',
              onTap: () => context.pushNamed('diagnostics'),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                'ReconSnap · v$_appVersion',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

void _showSupportedBanks(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.sm,
                bottom: AppSpacing.xs,
              ),
              child: Text(
                'Supported banks',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.sm,
                bottom: AppSpacing.md,
              ),
              child: Text(
                'Support starts narrow so every template is validated. More banks '
                'are added as real statements are tested.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            for (final bank in launchBanks)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: const Icon(
                  Icons.account_balance_rounded,
                  color: ReconSnapColors.ink700,
                ),
                title: Text(bank.name),
                subtitle: Text(bank.countryCode),
                trailing: _supportPill(bank.supportLevel),
              ),
          ],
        ),
      ),
    ),
  );
}

StatusPill _supportPill(BankSupportLevel level) {
  final (label, tone) = switch (level) {
    BankSupportLevel.templateReady => ('Template ready', PillTone.success),
    BankSupportLevel.beta => ('Beta', PillTone.info),
    BankSupportLevel.requested => ('Requested', PillTone.neutral),
  };
  return StatusPill(label: label, tone: tone);
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
