import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/reconsnap_theme.dart';
import '../../../app/widgets/app_components.dart';
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
                padding: AppSpacing.page,
                children: [
                  _StatusCard(report: report),
                  const SizedBox(height: AppSpacing.lg),
                  _MetricGrid(report: report),
                  const SizedBox(height: AppSpacing.xl),
                  SectionHeader(title: 'Review notes'),
                  const SizedBox(height: AppSpacing.md),
                  if (report.issues.isEmpty)
                    const _NoteTile(
                      title: 'No blocking issues',
                      message:
                          'The statement passed the current validation checks.',
                      tone: PillTone.success,
                    )
                  else
                    ...report.issues.map(
                      (issue) => _NoteTile(
                        title: issue.title,
                        message: issue.message,
                        tone: _toneFor(issue.severity),
                      ),
                    ),
                  ...state.warnings.map(
                    (w) => _NoteTile(
                      title: 'Parser note',
                      message: w,
                      tone: PillTone.info,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton.icon(
                    onPressed: () => _exportCsv(context, ref),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Export CSV'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.grid_on_rounded),
                    label: const Text('Export XLSX (coming soon)'),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final state = ref.read(conversionControllerProvider);
    final job = state.activeJob;
    if (job == null) return;
    final exporter = ref.read(csvExportServiceProvider);
    final file = await exporter.writeCsv(
      filename: job.filename,
      transactions: state.transactions,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV exported to ${file.path}')),
      );
    }
  }

  static PillTone _toneFor(ValidationSeverity s) => switch (s) {
        ValidationSeverity.pass => PillTone.success,
        ValidationSeverity.warning => PillTone.warning,
        ValidationSeverity.fail => PillTone.danger,
      };
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.report});

  final ValidationReport report;

  @override
  Widget build(BuildContext context) {
    final passed = report.isPassed;
    final fg = passed ? ReconSnapColors.accentGreenDark : ReconSnapColors.riskRed;
    final bg = passed ? ReconSnapColors.successSurface : ReconSnapColors.riskSurface;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.all(AppRadius.lg),
        border: Border.all(color: fg.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.all(AppRadius.md),
            ),
            child: Icon(
              passed ? Icons.verified_rounded : Icons.warning_amber_rounded,
              color: fg,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passed ? 'Ready for export' : 'Needs review',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: fg),
                ),
                const SizedBox(height: 3),
                Text(
                  passed
                      ? 'No blocking balance issues were found.'
                      : 'Fix the highlighted issues before sending to accounting software.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: fg.withValues(alpha: 0.85),
                      ),
                ),
              ],
            ),
          ),
        ],
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
      childAspectRatio: 1.7,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      children: [
        _MetricCard(label: 'Opening balance', value: _amount(report.openingBalance)),
        _MetricCard(label: 'Closing balance', value: _amount(report.closingBalance)),
        _MetricCard(label: 'Total debits', value: _amount(report.totalDebits), tone: PillTone.danger),
        _MetricCard(label: 'Total credits', value: _amount(report.totalCredits), tone: PillTone.success),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, this.tone});

  final String label;
  final String value;
  final PillTone? tone;

  @override
  Widget build(BuildContext context) {
    final accent = switch (tone) {
      PillTone.success => ReconSnapColors.accentGreenDark,
      PillTone.danger => ReconSnapColors.riskRed,
      _ => ReconSnapColors.ink900,
    };
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({
    required this.title,
    required this.message,
    required this.tone,
  });

  final String title;
  final String message;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      PillTone.success => ReconSnapColors.accentGreenDark,
      PillTone.warning => ReconSnapColors.warningAmber,
      PillTone.danger => ReconSnapColors.riskRed,
      PillTone.info => ReconSnapColors.actionBlue,
      PillTone.neutral => ReconSnapColors.mutedInk,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SoftCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 3),
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(message, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _amount(double? value) {
  if (value == null) return '—';
  return NumberFormat('#,##0.00').format(value);
}
