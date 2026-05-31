import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/reconsnap_theme.dart';
import '../../../app/widgets/app_components.dart';
import '../../../core/models/conversion_job.dart';
import '../../../core/models/statement_transaction.dart';
import 'conversion_controller.dart';

const _lowConfidence = 0.85;

class PreviewScreen extends ConsumerWidget {
  const PreviewScreen({required this.job, super.key});

  final ConversionJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversionControllerProvider);
    final transactions = state.transactions;
    final needsReview =
        transactions.where((t) => t.confidence < _lowConfidence).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Review rows')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            _SummaryCard(job: job, rows: transactions.length, needsReview: needsReview),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(title: '${transactions.length} transactions'),
            const SizedBox(height: AppSpacing.md),
            ...transactions.map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _TransactionTile(transaction: row),
                )),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: () => context.pushNamed('validation'),
              icon: const Icon(Icons.fact_check_rounded),
              label: const Text('Run balance validation'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.job,
    required this.rows,
    required this.needsReview,
  });

  final ConversionJob job;
  final int rows;
  final int needsReview;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_rounded, color: ReconSnapColors.ink700),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  job.filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${job.bank.name} · $rows extracted rows',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (needsReview == 0)
                const StatusPill(
                  label: 'All rows reconciled',
                  tone: PillTone.success,
                  icon: Icons.check_circle_rounded,
                )
              else
                StatusPill(
                  label: '$needsReview need review',
                  tone: PillTone.warning,
                  icon: Icons.flag_rounded,
                ),
              const StatusPill(label: 'Tap a row to edit', icon: Icons.edit_note_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.transaction});

  final StatementTransaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCredit = transaction.credit != null;
    final isLow = transaction.confidence < _lowConfidence;
    final amount = isCredit ? transaction.credit : transaction.debit;

    return SoftCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      onTap: () => _showEditSheet(context, ref, transaction),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isLow
                  ? ReconSnapColors.warningSurface
                  : ReconSnapColors.successSurface,
              borderRadius: AppRadius.all(AppRadius.sm),
            ),
            child: Icon(
              isLow ? Icons.priority_high_rounded : Icons.check_rounded,
              size: 20,
              color: isLow
                  ? ReconSnapColors.warningAmber
                  : ReconSnapColors.accentGreenDark,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('d MMM yyyy').format(transaction.date)}  ·  Bal ${_money(transaction.balance, transaction.currency)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${isCredit ? '+' : '−'}${_money(amount, transaction.currency)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isCredit
                  ? ReconSnapColors.accentGreenDark
                  : ReconSnapColors.ink900,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    StatementTransaction transaction,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditSheet(transaction: transaction, ref: ref),
    );
  }
}

class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.transaction, required this.ref});

  final StatementTransaction transaction;
  final WidgetRef ref;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _description;
  late final TextEditingController _amount;
  late bool _isCredit;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _description = TextEditingController(text: t.description);
    _isCredit = t.credit != null;
    _amount = TextEditingController(
      text: ((t.credit ?? t.debit) ?? 0).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ReconSnapColors.border,
                borderRadius: AppRadius.all(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Edit transaction', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount'),
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Debit'), icon: Icon(Icons.south_west_rounded)),
              ButtonSegment(value: true, label: Text('Credit'), icon: Icon(Icons.north_east_rounded)),
            ],
            selected: {_isCredit},
            onSelectionChanged: (s) => setState(() => _isCredit = s.first),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Save correction'),
          ),
        ],
      ),
    );
  }

  void _save() {
    final value = double.tryParse(_amount.text.replaceAll(',', '')) ?? 0;
    final t = widget.transaction;
    // Construct directly: copyWith cannot null out the opposite column when
    // switching between debit and credit.
    final updated = StatementTransaction(
      id: t.id,
      date: t.date,
      description: _description.text.trim(),
      debit: _isCredit ? null : value,
      credit: _isCredit ? value : null,
      balance: t.balance,
      currency: t.currency,
      confidence: 1,
      sourcePage: t.sourcePage,
      sourceLine: t.sourceLine,
      notes: t.notes,
    );
    widget.ref
        .read(conversionControllerProvider.notifier)
        .updateTransaction(updated);
    Navigator.of(context).pop();
  }
}

String _money(double? value, String currency) {
  if (value == null) return '—';
  return '${NumberFormat('#,##0.00').format(value)} $currency';
}
