import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/reconsnap_theme.dart';
import '../../../app/widgets/app_components.dart';
import '../../../core/models/conversion_job.dart';
import '../../conversion/presentation/conversion_controller.dart';
import '../../conversion/presentation/result_summary.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  static const routeName = 'history';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(conversionControllerProvider).history;

    return Scaffold(
      appBar: AppBar(title: const Text('Conversion history')),
      body: SafeArea(
        child: history.isEmpty
            ? const _Empty()
            : ListView(
                padding: AppSpacing.page,
                children: [
                  for (final group in _groupByMonth(history)) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                      ),
                      child: Eyebrow(group.label),
                    ),
                    for (final job in group.jobs) ...[
                      _HistoryTile(
                        job: job,
                        onTap: () {
                          ref
                              .read(conversionControllerProvider.notifier)
                              .openJob(job);
                          context.pushNamed('validation');
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ],
              ),
      ),
    );
  }

  /// Groups conversions into month buckets (newest first) so History reads as a
  /// workspace, not a flat log. Re-opening any job lets the user re-export from
  /// the Result without re-converting.
  static List<_MonthGroup> _groupByMonth(List<ConversionJob> jobs) {
    final groups = <String, _MonthGroup>{};
    for (final job in jobs) {
      final key = DateFormat('MMMM yyyy').format(job.createdAt);
      (groups[key] ??= _MonthGroup(key)).jobs.add(job);
    }
    return groups.values.toList();
  }
}

class _MonthGroup {
  _MonthGroup(this.label);
  final String label;
  final List<ConversionJob> jobs = [];
}

class _Empty extends ConsumerWidget {
  const _Empty();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: AppSpacing.page,
      children: [
        SoftCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: ReconSnapColors.subtle,
                  borderRadius: AppRadius.all(AppRadius.md),
                ),
                child: const Icon(
                  Icons.folder_open_rounded,
                  size: 28,
                  color: ReconSnapColors.mutedInk,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No saved conversions yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Convert a statement to see it here with its verdict and exports — '
                'or take the sample for a spin first.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => context.pushNamed('upload'),
                child: const Text('Convert a statement'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () async {
                  await ref
                      .read(conversionControllerProvider.notifier)
                      .startMockConversion();
                  if (context.mounted) context.pushNamed('processing');
                },
                child: const Text('See a sample result'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.job, required this.onTap});

  final ConversionJob job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reconciled = job.fullyReconciled;

    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: ReconSnapColors.subtle,
              borderRadius: AppRadius.all(AppRadius.sm),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: ReconSnapColors.ink700,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
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
                const SizedBox(height: 3),
                Text(
                  '${job.bank.name} · ${job.verdictLabel} · ${DateFormat('d MMM').format(job.createdAt)}',
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
    );
  }
}
