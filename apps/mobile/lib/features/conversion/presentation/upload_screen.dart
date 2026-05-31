import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/reconsnap_theme.dart';
import '../../../core/models/bank.dart';
import 'conversion_controller.dart';

class UploadScreen extends ConsumerWidget {
  const UploadScreen({super.key});

  static const routeName = 'upload';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversionControllerProvider);
    final controller = ref.read(conversionControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Upload statement')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Choose a bank pack',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: ReconSnapColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'MVP support starts narrow so each template can be validated properly.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: ReconSnapColors.mutedInk),
            ),
            const SizedBox(height: 16),
            ...launchBanks.map(
              (bank) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BankOption(
                  bank: bank,
                  selected: state.selectedBank.id == bank.id,
                  onTap: () => controller.selectBank(bank),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload PDF',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Digital PDFs are parsed locally first. Scanned statements will use OCR later.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ReconSnapColors.mutedInk,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf'],
                        );
                        final filename = result?.files.single.name;
                        await controller.startMockConversion(
                          filename: filename,
                        );
                        if (context.mounted) {
                          context.goNamed('processing');
                        }
                      },
                      icon: const Icon(Icons.folder_open_rounded),
                      label: const Text('Browse PDF'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await controller.startMockConversion();
                        if (context.mounted) {
                          context.goNamed('processing');
                        }
                      },
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Run demo conversion'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _PasswordNote(),
          ],
        ),
      ),
    );
  }
}

class _BankOption extends StatelessWidget {
  const _BankOption({
    required this.bank,
    required this.selected,
    required this.onTap,
  });

  final Bank bank;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = switch (bank.supportLevel) {
      BankSupportLevel.templateReady => 'Template ready',
      BankSupportLevel.beta => 'Beta template',
      BankSupportLevel.requested => 'Requested',
    };

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected
              ? ReconSnapColors.accentGreen
              : ReconSnapColors.mutedInk,
        ),
        title: Text(bank.name),
        subtitle: Text('${bank.countryCode} - $label'),
        trailing: const Icon(Icons.account_balance_rounded),
      ),
    );
  }
}

class _PasswordNote extends StatelessWidget {
  const _PasswordNote();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: ReconSnapColors.actionBlue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Password-protected statement support is part of the parser architecture. The password will be used only to unlock the file for conversion.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ReconSnapColors.mutedInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
