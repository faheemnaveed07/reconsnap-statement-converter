import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/copy/trust_copy.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/reconsnap_theme.dart';
import '../../../app/widgets/app_components.dart';
import '../../../core/models/bank.dart';
import '../../billing/presentation/entitlements_controller.dart';
import 'conversion_controller.dart';
import 'home_screen.dart' show BankSupportLabel;

/// Upload — **file first, bank second.** Pick a source; we detect the bank from
/// the file and ask you to confirm it (turning a friction step into a trust
/// moment), then convert. The sample is equal-weight, not buried.
class UploadScreen extends ConsumerWidget {
  const UploadScreen({super.key});

  static const routeName = 'upload';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(conversionControllerProvider.notifier);
    final entitlements = ref.watch(entitlementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Convert a statement'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: GestureDetector(
                onTap: () => context.pushNamed('paywall'),
                child: StatusPill(
                  label: entitlements.isPro
                      ? 'Pro'
                      : '${entitlements.availableCredits} left',
                  tone: entitlements.isPro ? PillTone.success : PillTone.info,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            Text(
              'Where is your statement?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Pick a source. We detect the bank from the file and ask you to '
              'confirm it before converting.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            _SourceOption(
              icon: Icons.picture_as_pdf_rounded,
              emphasised: true,
              title: 'PDF statement',
              subtitle: 'Best for digital bank statements',
              onTap: () => _browse(context, ref),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SourceOption(
              icon: Icons.photo_camera_rounded,
              title: 'Photo or scan',
              subtitle: 'Snap a paper statement, or pick an image',
              onTap: () => _pickImageSource(context, ref),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SourceOption(
              icon: Icons.auto_awesome_rounded,
              title: 'Try a sample',
              subtitle: 'See the full flow with sample data — free',
              onTap: () async {
                await controller.startMockConversion();
                if (context.mounted) context.goNamed('processing');
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            const _PrivacyNote(),
          ],
        ),
      ),
    );
  }

  Future<void> _browse(BuildContext context, WidgetRef ref) async {
    if (!ref.read(entitlementsProvider).canConvert) {
      context.pushNamed('paywall');
      return;
    }
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null || !context.mounted) return;

    final bank = await _confirmBank(context, ref, detectFrom: file.name);
    if (bank == null || !context.mounted) return;
    ref.read(conversionControllerProvider.notifier).selectBank(bank);
    await ref
        .read(conversionControllerProvider.notifier)
        .startConversion(bytes: bytes, filename: file.name);
    if (context.mounted) context.goNamed('processing');
  }

  Future<void> _pickImageSource(BuildContext context, WidgetRef ref) async {
    if (!ref.read(entitlementsProvider).canConvert) {
      context.pushNamed('paywall');
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.image_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    // Capture guidance before the shot — a clean frame is the difference between
    // a clean read and a poor one, so we coach it up front rather than failing
    // late.
    if (source == ImageSource.camera) {
      final go = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        builder: (_) => const _CaptureGuidance(),
      );
      if (go != true || !context.mounted) return;
    }
    final image = await ImagePicker().pickImage(source: source);
    if (image == null || !context.mounted) return;

    final bank = await _confirmBank(context, ref, detectFrom: image.name);
    if (bank == null || !context.mounted) return;
    ref.read(conversionControllerProvider.notifier).selectBank(bank);
    await ref
        .read(conversionControllerProvider.notifier)
        .startImageConversion(imagePath: image.path, filename: image.name);
    if (context.mounted) context.goNamed('processing');
  }

  Future<Bank?> _confirmBank(
    BuildContext context,
    WidgetRef ref, {
    required String detectFrom,
  }) {
    final detected = detectBankFromFilename(detectFrom);
    final initial =
        detected ?? ref.read(conversionControllerProvider).selectedBank;
    return showModalBottomSheet<Bank>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _ConfirmBankSheet(
        initial: initial,
        detectedFromName: detected != null,
      ),
    );
  }
}

/// A genuine, explainable detection signal: match the file name against the
/// known banks. Honest — we tell the user it came from the file name and let
/// them override — never a fabricated confidence percentage.
Bank? detectBankFromFilename(String filename) {
  final name = filename.toLowerCase();
  for (final bank in launchBanks) {
    final id = bank.id.split('_').last;
    if (name.contains(bank.name.toLowerCase()) || name.contains(id)) {
      return bank;
    }
  }
  // A couple of common aliases worth recognising.
  if (name.contains('enbd') || name.contains('emirates')) {
    return launchBanks.firstWhere((b) => b.id == 'ae_emirates_nbd');
  }
  return null;
}

/// Confirm-the-bank sheet shown *after* the file is chosen. Pre-selects the
/// detected bank; any bank with no validated template says so honestly and
/// offers the generic balance-reconciling parser rather than blocking.
class _ConfirmBankSheet extends StatefulWidget {
  const _ConfirmBankSheet({
    required this.initial,
    required this.detectedFromName,
  });

  final Bank initial;
  final bool detectedFromName;

  @override
  State<_ConfirmBankSheet> createState() => _ConfirmBankSheetState();
}

class _ConfirmBankSheetState extends State<_ConfirmBankSheet> {
  late Bank _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    final beta = _selected.supportLevel != BankSupportLevel.templateReady;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.detectedFromName ? 'Confirm the bank' : 'Which bank?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.detectedFromName
                    ? 'Detected from the file name. Not right? Pick the correct '
                          'bank below.'
                    : "We couldn't tell from the file name — choose the bank "
                          'this statement is from.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final bank in launchBanks)
                _BankOption(
                  bank: bank,
                  selected: bank.id == _selected.id,
                  onTap: () => setState(() => _selected = bank),
                ),
              if (beta) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: ReconSnapColors.reviewSurface,
                    borderRadius: AppRadius.all(AppRadius.md),
                    border: Border.all(
                      color: ReconSnapColors.ochre.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: ReconSnapColors.ochre,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          "${_selected.name} doesn't have a fully validated "
                          'template yet. We’ll use the generic '
                          'balance-reconciling parser (beta) — it works across '
                          'layouts, and every row is still checked.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_selected),
                child: const Text('Convert'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Capture guidance shown before the camera opens — coaches a legible shot so a
/// bad scan is prevented, not caught late after a generic failure.
class _CaptureGuidance extends StatelessWidget {
  const _CaptureGuidance();

  static const _tips = [
    (
      Icons.crop_free_rounded,
      'Fill the frame',
      'Get the whole page in, edge to edge.',
    ),
    (
      Icons.wb_sunny_outlined,
      'Even light',
      'Avoid glare, shadows and flash hot-spots.',
    ),
    (
      Icons.straighten_rounded,
      'Flat and straight',
      'Flatten the page; shoot from directly above.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Before you shoot',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final (icon, title, body) in _tips)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: ReconSnapColors.terracotta, size: 22),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            body,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Open camera'),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Text(
                'A clear digital PDF always reads best.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A large tappable "source" row — icon tile, title, subtitle, chevron.
class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasised = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// The primary option (PDF) gets the solid ink icon tile.
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: emphasised
                  ? ReconSnapColors.ink
                  : ReconSnapColors.containerHigh,
              borderRadius: AppRadius.all(AppRadius.md),
            ),
            child: Icon(
              icon,
              size: 24,
              color: emphasised
                  ? ReconSnapColors.paper
                  : ReconSnapColors.ink900,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: ReconSnapColors.ink400,
          ),
        ],
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
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? ReconSnapColors.terracotta
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
            StatusPill(
              label: bank.supportLevel.label,
              tone: bank.supportLevel.tone,
            ),
          ],
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: ReconSnapColors.containerLow,
        borderRadius: AppRadius.all(AppRadius.lg),
        border: Border.all(color: ReconSnapColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_rounded,
            color: ReconSnapColors.mossDeep,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${TrustCopy.oneLine} Any password is used only to unlock the PDF '
              'for this conversion.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
