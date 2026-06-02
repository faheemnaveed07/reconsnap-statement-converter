import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/reconsnap_theme.dart';
import '../../../app/widgets/app_components.dart';
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
      appBar: AppBar(title: const Text('Convert statement')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            Text(
              'Choose a bank',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Support starts narrow so every template can be validated properly.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            ...launchBanks.map(
              (bank) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _BankOption(
                  bank: bank,
                  selected: state.selectedBank.id == bank.id,
                  onTap: () => controller.selectBank(bank),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: ReconSnapColors.ink700,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Upload PDF',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Digital PDFs are supported today. Scanned statements will use OCR in a later release.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: () => _browse(context, controller),
                    icon: const Icon(Icons.folder_open_rounded),
                    label: const Text('Browse PDF'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await controller.startMockConversion();
                      if (context.mounted) context.goNamed('processing');
                    },
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Run demo conversion'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const _PrivacyNote(),
          ],
        ),
      ),
    );
  }

  Future<void> _browse(
    BuildContext context,
    ConversionController controller,
  ) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return;
    await controller.startConversion(bytes: bytes, filename: file.name);
    if (context.mounted) context.goNamed('processing');
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
    final (label, tone) = switch (bank.supportLevel) {
      BankSupportLevel.templateReady => ('Template ready', PillTone.success),
      BankSupportLevel.beta => ('Beta template', PillTone.info),
      BankSupportLevel.requested => ('Requested', PillTone.neutral),
    };

    return Container(
      decoration: BoxDecoration(
        color: ReconSnapColors.card,
        borderRadius: AppRadius.all(AppRadius.lg),
        border: Border.all(
          color: selected ? ReconSnapColors.ink : ReconSnapColors.border,
          width: selected ? 1.6 : 1,
        ),
        boxShadow: selected ? AppShadows.card : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.all(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected
                      ? ReconSnapColors.accentGreen
                      : ReconSnapColors.ink400,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bank.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bank.countryCode,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                StatusPill(label: label, tone: tone),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: ReconSnapColors.subtle,
        borderRadius: AppRadius.all(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: ReconSnapColors.actionBlue),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Statements are processed entirely on your device and never uploaded. Passwords are used only to unlock the PDF for this conversion.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
