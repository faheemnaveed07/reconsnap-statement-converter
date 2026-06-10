import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/reconsnap_theme.dart';
import '../../../app/widgets/app_components.dart';
import '../../../core/models/conversion_job.dart';
import '../../../core/models/statement_transaction.dart';
import '../../../core/models/validation_report.dart';
import '../../../core/ocr/ocr_legibility.dart';
import '../../../core/services/statement_exporter.dart';
import 'conversion_controller.dart';
import 'export_destinations.dart';
import 'result_summary.dart';
import 'rows_tab.dart';

/// The Result — the most important screen in the product, where trust is won or
/// quietly lost. It leads with the reconciliation proof, then offers two tabs:
/// **Rows** (every transaction, auditable) and **Checks** (the balance maths and
/// validation notes). Validation already ran the moment the conversion landed —
/// there is no fake "Run balance validation" button.
class ValidationScreen extends ConsumerWidget {
  const ValidationScreen({super.key});

  static const routeName = 'validation';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversionControllerProvider);
    final job = state.activeJob;
    final report = job?.validationReport;

    if (job == null || report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: const Center(child: Text('No conversion selected.')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Result'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Rows'),
              Tab(text: 'Checks'),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _ReconciliationHero(job: job),
              ),
              if (state.scanLegibility != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: StatusPill(
                      label: 'Scan legibility: ${state.scanLegibility!.label}',
                      tone: switch (state.scanLegibility!) {
                        ScanLegibility.good => PillTone.success,
                        ScanLegibility.fair => PillTone.warning,
                        ScanLegibility.poor => PillTone.danger,
                      },
                      icon: Icons.document_scanner_outlined,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: TabBarView(
                  children: [
                    RowsTab(transactions: state.transactions),
                    _ChecksTab(job: job, warnings: state.warnings),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _ExportBar(job: job),
      ),
    );
  }
}

/// Leads with the reconciliation statement, to the cent. This is the proof — not
/// "trust us", but "here's the maths, and it checks out (or here's exactly where
/// it doesn't)."
class _ReconciliationHero extends StatelessWidget {
  const _ReconciliationHero({required this.job});

  final ConversionJob job;

  @override
  Widget build(BuildContext context) {
    final report = job.validationReport;
    final reconciles = report.reconcilesToTheCent;
    final delta = report.reconciliationDelta;
    final flagged = job.flaggedCount;

    // Choose the verdict tone honestly: moss only when the balance reconciles
    // AND nothing is flagged; ochre when something needs eyes; brick when the
    // maths is actually off.
    final (fg, bg, headline) = (delta != null && !reconciles)
        ? (
            ReconSnapColors.brick,
            ReconSnapColors.failSurface,
            'Off by ${formatMoney(delta.abs())}',
          )
        : (flagged > 0)
        ? (
            ReconSnapColors.ochre,
            ReconSnapColors.reviewSurface,
            '$flagged ${flagged == 1 ? 'row needs' : 'rows need'} review',
          )
        : (
            ReconSnapColors.mossDeep,
            ReconSnapColors.verifiedSurface,
            'Reconciled to the cent',
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.all(AppRadius.lg),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                reconciles && flagged == 0
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: fg,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  headline,
                  style: ReconSnapTheme.serif(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: ReconSnapColors.ink900,
                  ),
                ),
              ),
            ],
          ),
          if (report.computedClosing != null) ...[
            const SizedBox(height: AppSpacing.md),
            _EquationLine(report: report),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            _verifiedSentence(job),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  static String _verifiedSentence(ConversionJob job) {
    final v = job.verifiedCount;
    final n = job.rowCount;
    if (job.flaggedCount == 0) {
      return 'All $n rows verified against the running balance.';
    }
    return '$v of $n rows verified by balance; ${job.flaggedCount} need your eyes.';
  }
}

/// The maths, spelled out: opening + credits − debits = computed closing, then
/// compared to the statement's stated closing.
class _EquationLine extends StatelessWidget {
  const _EquationLine({required this.report});

  final ValidationReport report;

  @override
  Widget build(BuildContext context) {
    final computed = report.computedClosing!;
    final stated = report.closingBalance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opening ${formatMoney(report.openingBalance!)}  '
          '+ credits ${formatMoney(report.totalCredits)}  '
          '− debits ${formatMoney(report.totalDebits)}',
          style: ReconSnapTheme.mono(
            fontSize: 12.5,
            color: ReconSnapColors.ink700,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '= ${formatMoney(computed)}'
          '${stated == null ? '' : '   (statement: ${formatMoney(stated)})'}',
          style: ReconSnapTheme.mono(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ReconSnapColors.ink900,
          ),
        ),
      ],
    );
  }
}

/// The "Checks" tab — the relabeled verification score, the balance grid, and
/// the validation notes.
class _ChecksTab extends StatelessWidget {
  const _ChecksTab({required this.job, required this.warnings});

  final ConversionJob job;
  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    final report = job.validationReport;
    return ListView(
      padding: AppSpacing.page,
      children: [
        // Relabeled score — decomposable, with its denominator.
        SoftCard(
          child: Column(
            children: [
              TrustRing(
                percent: job.rowCount == 0
                    ? 1
                    : job.verifiedCount / job.rowCount,
                centerText: '${job.verifiedCount}/${job.rowCount}',
                label: 'Rows auto-verified',
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                job.flaggedCount == 0
                    ? 'Every row verified by balance.'
                    : '${job.verifiedCount} of ${job.rowCount} rows verified by '
                          'balance; ${job.flaggedCount} need your eyes.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.7,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          children: [
            _MetricCard(label: 'Opening balance', value: report.openingBalance),
            _MetricCard(label: 'Closing balance', value: report.closingBalance),
            _MetricCard(label: 'Total debits', value: report.totalDebits),
            _MetricCard(label: 'Total credits', value: report.totalCredits),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: 'Validation notes'),
        const SizedBox(height: AppSpacing.md),
        if (report.issues.isEmpty)
          const _NoteTile(
            title: 'No blocking issues',
            message: 'The statement passed the current validation checks.',
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
        ...warnings.map(
          (w) =>
              _NoteTile(title: 'Parser note', message: w, tone: PillTone.info),
        ),
      ],
    );
  }

  static PillTone _toneFor(ValidationSeverity s) => switch (s) {
    ValidationSeverity.pass => PillTone.success,
    ValidationSeverity.warning => PillTone.warning,
    ValidationSeverity.fail => PillTone.danger,
  };
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
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
              value == null ? '—' : formatMoney(value!),
              style: ReconSnapTheme.mono(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: ReconSnapColors.ink900,
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
      PillTone.success => ReconSnapColors.mossDeep,
      PillTone.warning => ReconSnapColors.ochre,
      PillTone.danger => ReconSnapColors.brick,
      PillTone.info => ReconSnapColors.terracotta,
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

/// Persistent export action. Opens the destination → preview flow rather than
/// jumping blind to the OS share sheet.
class _ExportBar extends ConsumerWidget {
  const _ExportBar({required this.job});

  final ConversionJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Builder(
          builder: (buttonContext) => ElevatedButton.icon(
            onPressed: () => _startExport(buttonContext, ref),
            icon: const Icon(Icons.ios_share_rounded, size: 20),
            label: const Text('Export'),
          ),
        ),
      ),
    );
  }

  Future<void> _startExport(BuildContext context, WidgetRef ref) async {
    final remembered = ref.read(exportDestinationProvider);
    final destination = await showModalBottomSheet<ExportDestination>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _DestinationSheet(remembered: remembered),
    );
    if (destination == null || !context.mounted) return;

    ref.read(exportDestinationProvider.notifier).remember(destination);

    final state = ref.read(conversionControllerProvider);
    final activeJob = state.activeJob;
    if (activeJob == null) return;
    try {
      final file = await ref
          .read(statementExporterProvider)
          .export(
            destination.format,
            sourceFilename: activeJob.filename,
            transactions: state.transactions,
          );
      if (!context.mounted) return;
      await _shareFile(context, file, activeJob, destination);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not export the file. Please try again.'),
        ),
      );
    }
  }

  Future<void> _shareFile(
    BuildContext context,
    File file,
    ConversionJob job,
    ExportDestination destination,
  ) async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: destination.format.mimeType)],
          subject: '${job.bank.name} statement',
          text: 'Statement converted with ReconSnap.',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not export the file. Please try again.'),
        ),
      );
    }
  }
}

/// "Where's this going?" — destinations, with a live preview of the first rows
/// exactly as they'll export, and the column mapping the tool will see.
class _DestinationSheet extends ConsumerStatefulWidget {
  const _DestinationSheet({required this.remembered});

  final ExportDestination? remembered;

  @override
  ConsumerState<_DestinationSheet> createState() => _DestinationSheetState();
}

class _DestinationSheetState extends ConsumerState<_DestinationSheet> {
  late ExportDestination _selected =
      widget.remembered ?? ExportDestination.excel;

  @override
  Widget build(BuildContext context) {
    final txns = ref.read(conversionControllerProvider).transactions;
    final preview = txns.take(5).toList();
    final job = ref.read(conversionControllerProvider).activeJob;
    final outName = job == null
        ? null
        : StatementExporter.exportFilename(_selected.format, job.filename);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Where's this going?",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final d in ExportDestination.values)
                _DestinationTile(
                  destination: d,
                  selected: d == _selected,
                  onTap: () => setState(() => _selected = d),
                ),
              const SizedBox(height: AppSpacing.md),
              const Eyebrow('Preview'),
              const SizedBox(height: AppSpacing.sm),
              _PreviewTable(rows: preview),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _selected.mappingNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (outName != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(
                      Icons.insert_drive_file_outlined,
                      size: 15,
                      color: ReconSnapColors.mutedInk,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Saves as $outName',
                        style: ReconSnapTheme.mono(
                          fontSize: 11.5,
                          color: ReconSnapColors.mutedInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_selected),
                child: Text('Export to ${_selected.label}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final ExportDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SoftCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: onTap,
        borderColor: selected
            ? ReconSnapColors.terracotta
            : ReconSnapColors.border,
        child: Row(
          children: [
            Icon(destination.icon, color: ReconSnapColors.ink700, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    destination.subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? ReconSnapColors.terracotta
                  : ReconSnapColors.ink400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewTable extends StatelessWidget {
  const _PreviewTable({required this.rows});

  final List<StatementTransaction> rows;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 12, color: ReconSnapColors.border),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    rows[i].description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ReconSnapTheme.mono(fontSize: 11.5),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${rows[i].credit != null ? '+' : '−'}'
                  '${formatMoney((rows[i].credit ?? rows[i].debit) ?? 0)}',
                  style: ReconSnapTheme.mono(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (rows.isEmpty)
            Text(
              'No rows to preview.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
