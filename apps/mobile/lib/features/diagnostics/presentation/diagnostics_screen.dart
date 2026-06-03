import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/reconsnap_theme.dart';
import '../../../app/widgets/app_components.dart';
import '../../../core/diagnostics/conversion_outcome.dart';
import '../../conversion/presentation/conversion_controller.dart';

final _diagnosticsProvider = FutureProvider.autoDispose(
  (ref) => ref.read(diagnosticsStoreProvider).load(),
);

class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  static const routeName = 'diagnostics';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_diagnosticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('Could not load.')),
          data: (outcomes) => _Body(outcomes: outcomes, ref: ref),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.outcomes, required this.ref});

  final List<ConversionOutcome> outcomes;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final total = outcomes.length;
    final ok = outcomes.where((o) => o.isSuccess).length;

    return ListView(
      padding: AppSpacing.page,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: ReconSnapColors.subtle,
            borderRadius: AppRadius.all(AppRadius.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.shield_outlined,
                color: ReconSnapColors.actionBlue,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'These notes record only what happened (outcome, selected bank, '
                  'parser version) — never any text, amount, or detail from your '
                  'statements. Share them to help us support more layouts.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (total == 0)
          const _Empty()
        else ...[
          SectionHeader(
            title: 'Last $total · $ok converted',
            action: TextButton(
              onPressed: () => _share(outcomes),
              child: const Text('Share'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...outcomes.map((o) => _OutcomeTile(outcome: o)),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(diagnosticsStoreProvider).clear();
              ref.invalidate(_diagnosticsProvider);
            },
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Clear diagnostics'),
          ),
        ],
      ],
    );
  }

  void _share(List<ConversionOutcome> outcomes) {
    final lines = outcomes
        .map((o) {
          final when = DateFormat('yyyy-MM-dd HH:mm').format(o.at);
          return '$when | ${o.type.name} | ${o.bankId} | '
              '${o.parserVersion ?? '-'} | rows=${o.transactionCount} | '
              'reconciled=${o.reconciled ?? '-'}';
        })
        .join('\n');
    SharePlus.instance.share(
      ShareParams(
        subject: 'ReconSnap diagnostics',
        text:
            'ReconSnap conversion diagnostics (no statement content):\n\n$lines',
      ),
    );
  }
}

class _OutcomeTile extends StatelessWidget {
  const _OutcomeTile({required this.outcome});
  final ConversionOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final ok = outcome.isSuccess;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SoftCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(
              ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: ok
                  ? ReconSnapColors.accentGreenDark
                  : ReconSnapColors.warningAmber,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outcome.label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${outcome.bankId} · ${DateFormat('d MMM, HH:mm').format(outcome.at)}'
                    '${ok ? ' · ${outcome.transactionCount} rows' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          const Icon(
            Icons.insights_rounded,
            size: 28,
            color: ReconSnapColors.mutedInk,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No conversions yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
