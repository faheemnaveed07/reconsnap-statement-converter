import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/copy/trust_copy.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/reconsnap_theme.dart';
import '../../../app/widgets/app_components.dart';
import '../../../core/models/bank.dart';
import '../../../core/models/conversion_job.dart';
import '../../billing/presentation/entitlements_controller.dart';
import 'conversion_controller.dart';
import 'result_summary.dart';

/// Home — the start surface. It has exactly one job: get a real statement into
/// the converter, and reassure with *true* signals on the way. No dashboard, no
/// fabricated metrics, no decorative bento. Hierarchy comes from the editorial
/// headline, white space, and one ink CTA.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routeName = 'home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversionControllerProvider);
    final entitlements = ref.watch(entitlementsProvider);
    final lastResult = state.history.isEmpty ? null : state.history.first;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.gutter,
        title: const Wordmark(fontSize: 22),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          children: [
            const SizedBox(height: AppSpacing.sm),
            // 2 — display headline, plain and true.
            Text(
              'Turn a bank statement into clean, checked data.',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            // 3 — the guarantee, stated accurately.
            Text(
              TrustCopy.reconcileGuarantee,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xl),
            // 4 — one primary CTA, one quiet secondary link.
            ElevatedButton(
              onPressed: () => context.pushNamed('upload'),
              child: const Text('Convert a statement'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: () {
                  ref
                      .read(conversionControllerProvider.notifier)
                      .startMockConversion();
                  context.pushNamed('processing');
                },
                child: const Text('Try it with sample data'),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // 5 — real status line: conversions remaining + last true verdict.
            _StatusLine(
              creditsLabel: entitlements.isPro
                  ? 'Unlimited conversions'
                  : '${entitlements.availableCredits} '
                        '${entitlements.availableCredits == 1 ? 'conversion' : 'conversions'} remaining',
              lastResult: lastResult,
            ),
            const SizedBox(height: AppSpacing.xl),
            // 6 — supported banks, stated honestly.
            _SupportedBanksLine(onTap: () => _showSupportedBanks(context)),
            if (state.history.length > 1) ...[
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title: 'Recent conversions',
                action: TextButton(
                  onPressed: () => context.pushNamed('history'),
                  child: const Text('View all'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _RecentList(jobs: state.history.skip(1).take(3).toList()),
            ],
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
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supported banks',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'More are added as we validate each template. Tell us which to '
              'add next from Account → Request a bank.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final bank in launchBanks)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        bank.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    StatusPill(
                      label: bank.supportLevel.label,
                      tone: bank.supportLevel.tone,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Honest bank maturity, mapped to the trust traffic-light.
extension BankSupportLabel on BankSupportLevel {
  String get label => switch (this) {
    BankSupportLevel.templateReady => 'Template ready',
    BankSupportLevel.beta => 'Beta',
    BankSupportLevel.requested => 'Requested',
  };

  PillTone get tone => switch (this) {
    BankSupportLevel.templateReady => PillTone.success,
    BankSupportLevel.beta => PillTone.warning,
    BankSupportLevel.requested => PillTone.neutral,
  };
}

class _SupportedBanksLine extends StatelessWidget {
  const _SupportedBanksLine({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ready = launchBanks
        .where((b) => b.supportLevel != BankSupportLevel.requested)
        .length;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.all(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(
              Icons.account_balance_outlined,
              size: 18,
              color: ReconSnapColors.mutedInk,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '$ready UAE banks live, more added as we validate each template.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: ReconSnapColors.ink400,
            ),
          ],
        ),
      ),
    );
  }
}

/// Real status: conversions remaining, and the last result as one tappable row
/// carrying its *true* verdict (or hidden when there's nothing yet).
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.creditsLabel, required this.lastResult});

  final String creditsLabel;
  final ConversionJob? lastResult;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Eyebrow('Your plan'),
                const Spacer(),
                MonoText(
                  creditsLabel,
                  fontSize: 12,
                  color: ReconSnapColors.ink700,
                ),
              ],
            ),
          ),
          if (lastResult != null) ...[
            const Divider(height: 1, color: ReconSnapColors.border),
            _LastResultRow(job: lastResult!),
          ],
        ],
      ),
    );
  }
}

class _LastResultRow extends ConsumerWidget {
  const _LastResultRow({required this.job});

  final ConversionJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reconciled = job.fullyReconciled;
    return InkWell(
      onTap: () {
        ref.read(conversionControllerProvider.notifier).openJob(job);
        context.pushNamed('validation');
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last conversion · ${job.filename}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    job.verdictLabel,
                    style: ReconSnapTheme.mono(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: reconciled
                          ? ReconSnapColors.mossDeep
                          : ReconSnapColors.ochre,
                    ),
                  ),
                ],
              ),
            ),
            StatusPill(
              label: reconciled ? 'Reconciled' : 'Needs review',
              tone: reconciled ? PillTone.success : PillTone.warning,
              icon: reconciled ? Icons.check_rounded : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentList extends ConsumerWidget {
  const _RecentList({required this.jobs});

  final List<ConversionJob> jobs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < jobs.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: ReconSnapColors.border),
            _RecentRow(job: jobs[i]),
          ],
        ],
      ),
    );
  }
}

class _RecentRow extends ConsumerWidget {
  const _RecentRow({required this.job});

  final ConversionJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reconciled = job.fullyReconciled;
    return InkWell(
      onTap: () {
        ref.read(conversionControllerProvider.notifier).openJob(job);
        context.pushNamed('validation');
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.filename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${job.bank.name} · ${job.verdictLabel}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            StatusPill(
              label: reconciled ? 'Reconciled' : 'Review',
              tone: reconciled ? PillTone.success : PillTone.warning,
            ),
          ],
        ),
      ),
    );
  }
}
