import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/reconsnap_theme.dart';
import '../../../app/widgets/app_components.dart';
import '../../../core/categorization/transaction_categorizer.dart';
import '../../../core/models/statement_transaction.dart';
import 'conversion_controller.dart';
import 'result_summary.dart';

/// The "Rows" tab of the Result — every parsed transaction, auditable. Verified
/// rows are quiet; flagged rows show *why* and their source line; edited rows
/// are tagged "Edited by you" (never silently turned green). A filter jumps
/// straight to what needs eyes.
class RowsTab extends ConsumerStatefulWidget {
  const RowsTab({super.key, required this.transactions});

  final List<StatementTransaction> transactions;

  @override
  ConsumerState<RowsTab> createState() => _RowsTabState();
}

class _RowsTabState extends ConsumerState<RowsTab> {
  bool _onlyFlagged = false;

  @override
  Widget build(BuildContext context) {
    final all = widget.transactions;
    final flaggedCount = all
        .where((t) => t.confidence < kVerifyThreshold && !t.editedByUser)
        .length;
    final rows = _onlyFlagged
        ? all
              .where((t) => t.confidence < kVerifyThreshold && !t.editedByUser)
              .toList()
        : all;

    return ListView(
      padding: AppSpacing.page,
      children: [
        Row(
          children: [
            Text(
              '${all.length} transactions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            if (flaggedCount > 0)
              FilterChip(
                selected: _onlyFlagged,
                showCheckmark: false,
                label: Text(
                  _onlyFlagged
                      ? 'Showing flagged'
                      : 'Show $flaggedCount flagged',
                ),
                avatar: Icon(
                  Icons.flag_outlined,
                  size: 16,
                  color: _onlyFlagged
                      ? ReconSnapColors.paper
                      : ReconSnapColors.ochre,
                ),
                selectedColor: ReconSnapColors.ochre,
                labelStyle: TextStyle(
                  color: _onlyFlagged
                      ? ReconSnapColors.paper
                      : ReconSnapColors.ink700,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                onSelected: (v) => setState(() => _onlyFlagged = v),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: Text(
                'Nothing flagged — every row reconciled.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        else
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _RowTile(transaction: row),
            ),
          ),
      ],
    );
  }
}

class _RowTile extends ConsumerWidget {
  const _RowTile({required this.transaction});

  final StatementTransaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = transaction;
    final isCredit = t.credit != null;
    final amount = (isCredit ? t.credit : t.debit) ?? 0;
    final edited = t.editedByUser;
    final flagged = !edited && t.confidence < kVerifyThreshold;

    final (iconBg, iconFg, icon) = edited
        ? (
            ReconSnapColors.accentSurface,
            ReconSnapColors.terracotta,
            Icons.edit_rounded,
          )
        : flagged
        ? (
            ReconSnapColors.reviewSurface,
            ReconSnapColors.ochre,
            Icons.priority_high_rounded,
          )
        : (
            ReconSnapColors.verifiedSurface,
            ReconSnapColors.mossDeep,
            Icons.check_rounded,
          );

    return SoftCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      onTap: () => showRowEditSheet(context, ref, t),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: AppRadius.all(AppRadius.sm),
                ),
                child: Icon(icon, size: 20, color: iconFg),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('d MMM yyyy').format(t.date)}  ·  '
                      'Bal ${t.balance == null ? '—' : formatMoney(t.balance!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${isCredit ? '+' : '−'}${formatMoney(amount)}',
                style: ReconSnapTheme.mono(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ReconSnapColors.ink900,
                ),
              ),
            ],
          ),
          // Tags row: category, edited, flagged reason.
          if (t.category != null || edited || flagged) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (edited)
                  const StatusPill(
                    label: 'Edited by you',
                    tone: PillTone.info,
                    icon: Icons.edit_rounded,
                  ),
                if (flagged)
                  const StatusPill(
                    label: 'Needs review',
                    tone: PillTone.warning,
                    icon: Icons.flag_rounded,
                  ),
                if (t.category != null)
                  StatusPill(label: t.category!, icon: Icons.sell_outlined),
              ],
            ),
          ],
          // Why a row was flagged + its source line (the audit trail).
          if (flagged) ...[
            const SizedBox(height: 6),
            _SubNote(icon: Icons.help_outline_rounded, text: _flagReason(t)),
          ],
          if (edited && t.notes != null) ...[
            const SizedBox(height: 6),
            _SubNote(icon: Icons.history_rounded, text: t.notes!),
          ],
          if (t.sourcePage != null || t.sourceLine != null) ...[
            const SizedBox(height: 6),
            _SubNote(icon: Icons.description_outlined, text: _sourceRef(t)),
          ],
        ],
      ),
    );
  }

  static String _flagReason(StatementTransaction t) {
    if (t.balance != null) {
      return 'The running-balance change doesn’t match this amount — '
          'please confirm.';
    }
    return 'Low parser confidence on this row — please confirm.';
  }

  static String _sourceRef(StatementTransaction t) {
    final parts = <String>[];
    if (t.sourcePage != null) parts.add('page ${t.sourcePage}');
    if (t.sourceLine != null) parts.add('line ${t.sourceLine}');
    return 'Source: ${parts.join(', ')}';
  }
}

class _SubNote extends StatelessWidget {
  const _SubNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: ReconSnapColors.mutedInk),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

void showRowEditSheet(
  BuildContext context,
  WidgetRef ref,
  StatementTransaction transaction,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _EditSheet(transaction: transaction, ref: ref),
  );
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
  late String _category;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _description = TextEditingController(text: t.description);
    _isCredit = t.credit != null;
    _category = t.category ?? TransactionCategories.uncategorized;
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
    final t = widget.transaction;
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
          Text(
            'Edit transaction',
            style: Theme.of(context).textTheme.titleLarge,
          ),
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
              ButtonSegment(
                value: false,
                label: Text('Debit'),
                icon: Icon(Icons.south_west_rounded),
              ),
              ButtonSegment(
                value: true,
                label: Text('Credit'),
                icon: Icon(Icons.north_east_rounded),
              ),
            ],
            selected: {_isCredit},
            onSelectionChanged: (s) => setState(() => _isCredit = s.first),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _category,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              for (final c in TransactionCategories.all)
                DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Save correction'),
          ),
          if (t.editedByUser) ...[
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: _restore,
                child: const Text('Restore original'),
              ),
            ),
          ],
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
      // Preserve the parser's confidence — editing must NOT silently mark the
      // row auto-verified. The "Edited by you" tag carries the meaning instead.
      confidence: t.confidence,
      sourcePage: t.sourcePage,
      sourceLine: t.sourceLine,
      // Keep the original snapshot the first time a row is touched, so the
      // correction stays visible and reversible. Later edits don't overwrite it.
      notes: t.editedByUser ? t.notes : _originalNote(t),
      category: _category,
      editedByUser: true,
    );
    widget.ref
        .read(conversionControllerProvider.notifier)
        .updateTransaction(updated);
    Navigator.of(context).pop();
  }

  /// Reverses the user's correction back to what the parser originally read,
  /// recovered from the snapshot kept in [notes].
  void _restore() {
    final t = widget.transaction;
    final original = _parseOriginalNote(t.notes);
    if (original == null) {
      // Nothing to restore to — just clear the edited flag.
      widget.ref
          .read(conversionControllerProvider.notifier)
          .updateTransaction(t.copyWith(editedByUser: false, notes: null));
      Navigator.of(context).pop();
      return;
    }
    final restored = StatementTransaction(
      id: t.id,
      date: t.date,
      description: original.description,
      debit: original.isCredit ? null : original.amount,
      credit: original.isCredit ? original.amount : null,
      balance: t.balance,
      currency: t.currency,
      confidence: t.confidence,
      sourcePage: t.sourcePage,
      sourceLine: t.sourceLine,
      notes: null,
      category: t.category,
      editedByUser: false,
    );
    widget.ref
        .read(conversionControllerProvider.notifier)
        .updateTransaction(restored);
    Navigator.of(context).pop();
  }

  /// A human-readable, machine-recoverable record of what the row said before
  /// the user touched it — e.g. `Was DR 1,204.55 · "ATM WITHDRAWAL"`.
  static String _originalNote(StatementTransaction t) {
    final wasCredit = t.credit != null;
    final amount = (t.credit ?? t.debit) ?? 0;
    final sign = wasCredit ? 'CR' : 'DR';
    return 'Was $sign ${NumberFormat('#,##0.00').format(amount)} · '
        '"${t.description}"';
  }

  static _OriginalSnapshot? _parseOriginalNote(String? note) {
    if (note == null) return null;
    final m = RegExp(r'Was (CR|DR) ([\d.,]+) · "(.*)"').firstMatch(note);
    if (m == null) return null;
    final amount = double.tryParse(m.group(2)!.replaceAll(',', ''));
    if (amount == null) return null;
    return _OriginalSnapshot(
      isCredit: m.group(1) == 'CR',
      amount: amount,
      description: m.group(3)!,
    );
  }
}

class _OriginalSnapshot {
  const _OriginalSnapshot({
    required this.isCredit,
    required this.amount,
    required this.description,
  });
  final bool isCredit;
  final double amount;
  final String description;
}
