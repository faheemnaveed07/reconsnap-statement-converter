import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/conversion_job.dart';
import '../../../core/models/subscription_plan.dart';
import '../../../app/theme/reconsnap_theme.dart';
import 'conversion_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routeName = 'home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ReconSnap'),
        actions: [
          IconButton(
            tooltip: 'History',
            onPressed: () => context.pushNamed('history'),
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.pushNamed('settings'),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _HeroPanel(),
            const SizedBox(height: 16),
            const _CreditPanel(),
            const SizedBox(height: 24),
            Text(
              'Recent conversions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: ReconSnapColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            if (state.history.isEmpty)
              const _EmptyHistory()
            else
              ...state.history.map((job) => _HistoryTile(job: job)),
          ],
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ReconSnapColors.ink,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Bank PDFs to accountant-ready files',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: ReconSnapColors.ink,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Upload a statement, review extracted rows, run balance checks, and export clean CSV files.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ReconSnapColors.mutedInk,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.pushNamed('upload'),
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Convert statement'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditPanel extends StatelessWidget {
  const _CreditPanel();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.verified_user_rounded,
              color: ReconSnapColors.accentGreen,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Starter preview',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${starterPlan.pageAllowance} pages/month planned for ${starterPlan.monthlyPriceLabel}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ReconSnapColors.mutedInk,
                    ),
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

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              size: 42,
              color: ReconSnapColors.mutedInk,
            ),
            const SizedBox(height: 12),
            Text(
              'No conversions yet',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Your converted statements will appear here with validation status and export options.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: ReconSnapColors.mutedInk),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.job});

  final ConversionJob job;

  @override
  Widget build(BuildContext context) {
    final statusColor = job.validationReport.isPassed
        ? ReconSnapColors.accentGreen
        : ReconSnapColors.riskRed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: statusColor.withValues(alpha: 0.12),
            child: Icon(Icons.description_rounded, color: statusColor),
          ),
          title: Text(job.filename),
          subtitle: Text('${job.bank.name} - ${job.transactions.length} rows'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.pushNamed('validation'),
        ),
      ),
    );
  }
}
