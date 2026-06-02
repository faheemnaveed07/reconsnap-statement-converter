import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/reconsnap_theme.dart';
import '../../../app/widgets/app_components.dart';
import '../../../core/models/conversion_job.dart';
import '../../conversion/presentation/conversion_controller.dart';

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
            ? _Empty()
            : ListView.separated(
                padding: AppSpacing.page,
                itemCount: history.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, i) => _HistoryTile(
                  job: history[i],
                  onTap: () {
                    ref
                        .read(conversionControllerProvider.notifier)
                        .openJob(history[i]);
                    context.pushNamed('validation');
                  },
                ),
              ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.page,
      children: [
        SoftCard(
          padding: const EdgeInsets.all(AppSpacing.xxl),
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
                'Convert a statement to see it here with its validation status and exports.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
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
    final passed = job.validationReport.isPassed;

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
                  '${job.bank.name} · ${job.transactions.length} rows · ${DateFormat('d MMM').format(job.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusPill(
            label: passed ? 'Validated' : 'Review',
            tone: passed ? PillTone.success : PillTone.warning,
          ),
        ],
      ),
    );
  }
}
