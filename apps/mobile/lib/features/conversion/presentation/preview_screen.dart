import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/reconsnap_theme.dart';
import '../../../core/models/conversion_job.dart';
import '../../../core/models/statement_transaction.dart';
import 'conversion_controller.dart';

class PreviewScreen extends ConsumerWidget {
  const PreviewScreen({required this.job, super.key});

  final ConversionJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversionControllerProvider);
    final transactions = state.transactions;

    return Scaffold(
      appBar: AppBar(title: const Text('Review rows')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.filename,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${job.bank.name} - ${transactions.length} extracted rows',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ReconSnapColors.mutedInk,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...transactions.map((row) => _TransactionTile(transaction: row)),
            const SizedBox(height: 12),
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

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.transaction});

  final StatementTransaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM d');
    final isLowConfidence = transaction.confidence < 0.85;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: isLowConfidence
                ? ReconSnapColors.warningAmber.withValues(alpha: 0.12)
                : ReconSnapColors.accentGreen.withValues(alpha: 0.12),
            child: Icon(
              isLowConfidence
                  ? Icons.priority_high_rounded
                  : Icons.check_rounded,
              color: isLowConfidence
                  ? ReconSnapColors.warningAmber
                  : ReconSnapColors.accentGreen,
            ),
          ),
          title: Text(transaction.description),
          subtitle: Text(
            '${dateFormat.format(transaction.date)} - Balance ${_amount(transaction.balance)}',
          ),
          trailing: Text(
            transaction.credit != null
                ? '+${_amount(transaction.credit)}'
                : '-${_amount(transaction.debit)}',
            style: TextStyle(
              color: transaction.credit != null
                  ? ReconSnapColors.accentGreen
                  : ReconSnapColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          onTap: () => _showEditSheet(context, ref, transaction),
        ),
      ),
    );
  }

  void _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    StatementTransaction transaction,
  ) {
    final descriptionController = TextEditingController(
      text: transaction.description,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit transaction',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(conversionControllerProvider.notifier)
                      .updateTransaction(
                        transaction.copyWith(
                          description: descriptionController.text,
                          confidence: 1,
                        ),
                      );
                  Navigator.of(context).pop();
                },
                child: const Text('Save correction'),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _amount(double? value) {
  if (value == null) return '--';
  return value.toStringAsFixed(2);
}
