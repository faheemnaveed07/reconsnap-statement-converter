import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/reconsnap_theme.dart';
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
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (history.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No saved conversions yet. Run a demo conversion to see history states.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ReconSnapColors.mutedInk,
                    ),
                  ),
                ),
              )
            else
              ...history.map(
                (job) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.description_rounded),
                      title: Text(job.filename),
                      subtitle: Text(
                        '${job.bank.name} - ${job.transactions.length} rows',
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
