import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/reconsnap_theme.dart';
import '../../../core/models/validation_report.dart';
import 'conversion_controller.dart';

class ValidationScreen extends ConsumerWidget {
  const ValidationScreen({super.key});

  static const routeName = 'validation';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversionControllerProvider);
    final job = state.activeJob;
    final report = job?.validationReport;

    return Scaffold(
      appBar: AppBar(title: const Text('Validation report')),
      body: SafeArea(
        child: report == null
            ? const Center(child: Text('No conversion selected.'))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _StatusCard(report: report),
                  const SizedBox(height: 14),
                  _MetricGrid(report: report),
                  const SizedBox(height: 14),
                  Text(
                    'Review notes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (report.issues.isEmpty)
                    const _IssueTile(
                      title: 'No blocking issues',
                      message:
                          'The statement passed the current validation checks.',
                      severity: ValidationSeverity.pass,
                    )
                  else
                    ...report.issues.map(
                      (issue) => _IssueTile(
                        title: issue.title,
                        message: issue.message,
                        severity: issue.severity,
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final exporter = ref.read(csvExportServiceProvider);
                      final file = await exporter.writeCsv(
                        filename: job!.filename,
                        transactions: state.transactions,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('CSV exported to ${file.path}'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Export CSV'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.report});

  final ValidationReport report;

  @override
  Widget build(BuildContext context) {
    final passed = report.isPassed;
    final color = passed
        ? ReconSnapColors.accentGreen
        : ReconSnapColors.riskRed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(
                passed ? Icons.verified_rounded : Icons.warning_rounded,
                color: color,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    passed ? 'Ready for export' : 'Needs review',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    passed
                        ? 'No blocking balance issues were found.'
                        : 'Fix the highlighted issues before sending this to accounting software.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.report});

  final ValidationReport report;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.45,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _MetricCard(label: 'Opening', value: _amount(report.openingBalance)),
        _MetricCard(label: 'Closing', value: _amount(report.closingBalance)),
        _MetricCard(label: 'Debits', value: _amount(report.totalDebits)),
        _MetricCard(label: 'Credits', value: _amount(report.totalCredits)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: ReconSnapColors.mutedInk),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: ReconSnapColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({
    required this.title,
    required this.message,
    required this.severity,
  });

  final String title;
  final String message;
  final ValidationSeverity severity;

  @override
  Widget build(BuildContext context) {
    final color = switch (severity) {
      ValidationSeverity.pass => ReconSnapColors.accentGreen,
      ValidationSeverity.warning => ReconSnapColors.warningAmber,
      ValidationSeverity.fail => ReconSnapColors.riskRed,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: Icon(Icons.circle_rounded, color: color, size: 14),
          title: Text(title),
          subtitle: Text(message),
        ),
      ),
    );
  }
}

String _amount(double? value) {
  if (value == null) return '--';
  return value.toStringAsFixed(2);
}
