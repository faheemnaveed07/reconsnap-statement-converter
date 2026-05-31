import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/reconsnap_theme.dart';
import '../../../core/models/conversion_job.dart';
import 'conversion_controller.dart';
import 'preview_screen.dart';

class ProcessingScreen extends ConsumerWidget {
  const ProcessingScreen({super.key});

  static const routeName = 'processing';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversionControllerProvider);

    if (state.status == ConversionStatus.ready && state.activeJob != null) {
      return PreviewScreen(job: state.activeJob!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Processing')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: switch (state.status) {
            ConversionStatus.needsPassword => const _PasswordPrompt(),
            ConversionStatus.failed => _FailureCard(
              message: state.errorMessage ?? 'Please try again.',
            ),
            _ => const _ProcessingCard(),
          },
        ),
      ),
    );
  }
}

class _ProcessingCard extends StatelessWidget {
  const _ProcessingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 54,
              height: 54,
              child: CircularProgressIndicator(strokeWidth: 5),
            ),
            const SizedBox(height: 18),
            Text(
              'Reading statement structure',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'ReconSnap is extracting rows and reconciling them against the running balance.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ReconSnapColors.mutedInk,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailureCard extends StatelessWidget {
  const _FailureCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 54,
              color: ReconSnapColors.riskRed,
            ),
            const SizedBox(height: 18),
            Text(
              'Conversion failed',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ReconSnapColors.mutedInk,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => context.goNamed('upload'),
              child: const Text('Try another file'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordPrompt extends ConsumerStatefulWidget {
  const _PasswordPrompt();

  @override
  ConsumerState<_PasswordPrompt> createState() => _PasswordPromptState();
}

class _PasswordPromptState extends ConsumerState<_PasswordPrompt> {
  final _controller = TextEditingController();
  bool _obscured = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 44,
              color: ReconSnapColors.actionBlue,
            ),
            const SizedBox(height: 16),
            Text(
              'This statement is password-protected',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the password to unlock the file. It is used only to open the PDF for this conversion.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ReconSnapColors.mutedInk,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _controller,
              obscureText: _obscured,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'PDF password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscured
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  onPressed: () => setState(() => _obscured = !_obscured),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text('Unlock and convert'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final password = _controller.text;
    if (password.isEmpty) return;
    ref.read(conversionControllerProvider.notifier).submitPassword(password);
  }
}
