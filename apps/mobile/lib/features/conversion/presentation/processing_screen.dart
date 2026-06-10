import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/copy/trust_copy.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/reconsnap_theme.dart';
import '../../../app/widgets/app_components.dart';
import '../../../core/diagnostics/conversion_outcome.dart';
import '../../../core/models/conversion_job.dart';
import 'conversion_controller.dart';
import 'validation_screen.dart';

class ProcessingScreen extends ConsumerWidget {
  const ProcessingScreen({super.key});

  static const routeName = 'processing';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversionControllerProvider);

    if (state.status == ConversionStatus.ready && state.activeJob != null) {
      // Validation already ran the moment the conversion landed — go straight
      // to the unified Result (Rows + Checks). No fake "Run validation" step.
      return const ValidationScreen();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Processing')),
      body: SafeArea(
        child: switch (state.status) {
          ConversionStatus.needsPassword => const SingleChildScrollView(
            padding: AppSpacing.page,
            child: _PasswordPrompt(),
          ),
          ConversionStatus.failed => SingleChildScrollView(
            padding: AppSpacing.page,
            child: _FailureCard(
              cause: state.failureCause,
              message: state.errorMessage ?? 'Please try again.',
            ),
          ),
          ConversionStatus.lowLegibility => const SingleChildScrollView(
            padding: AppSpacing.page,
            child: _LowLegibilityCard(),
          ),
          _ => const _ProcessingView(),
        },
      ),
    );
  }
}

/// Honest processing view. No fake checklist, no scanner theatre, no "30–60
/// seconds" promise. A single quiet indicator shows the *real* current stage and
/// the elapsed time. Fast on-device parses pass through this in a blink and go
/// straight to the Result; only genuinely slow OCR dwells here.
class _ProcessingView extends ConsumerStatefulWidget {
  const _ProcessingView();

  @override
  ConsumerState<_ProcessingView> createState() => _ProcessingViewState();
}

class _ProcessingViewState extends ConsumerState<_ProcessingView> {
  final Stopwatch _watch = Stopwatch()..start();

  @override
  void initState() {
    super.initState();
    // A lightweight 1s rebuild so the elapsed counter ticks while we wait.
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {});
      return true;
    });
  }

  @override
  void dispose() {
    _watch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message =
        ref.watch(
          conversionControllerProvider.select((s) => s.processingMessage),
        ) ??
        'Working on it';
    final seconds = _watch.elapsed.inSeconds;

    return ListView(
      padding: AppSpacing.page,
      children: [
        const SizedBox(height: AppSpacing.xxl),
        Center(
          child: Column(
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                seconds < 1 ? 'Just a moment…' : 'Elapsed ${seconds}s',
                style: ReconSnapTheme.mono(
                  fontSize: 12,
                  color: ReconSnapColors.mutedInk,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        const _SecureNote(),
      ],
    );
  }
}

class _SecureNote extends StatelessWidget {
  const _SecureNote();

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
              TrustCopy.oneLine,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// A failure is a recoverable moment, not a dead end. Each cause gets its own
/// heading and a primary action tied to *that* cause (retake, upload the PDF,
/// request the bank, try the sample, send diagnostics), so "not supported"
/// becomes a next step instead of an exit.
class _FailureCard extends ConsumerWidget {
  const _FailureCard({required this.cause, required this.message});

  final ConversionOutcomeType? cause;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heading = switch (cause) {
      ConversionOutcomeType.notAStatement =>
        'This doesn’t look like a statement',
      ConversionOutcomeType.noTransactions => 'No transaction rows found',
      ConversionOutcomeType.unreadable ||
      ConversionOutcomeType.needsOcr => 'This scan is too unclear to read',
      _ => 'Something went wrong',
    };

    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: ReconSnapColors.failSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 28,
                color: ReconSnapColors.brick,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            heading,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          ..._actions(context, ref),
        ],
      ),
    );
  }

  List<Widget> _actions(BuildContext context, WidgetRef ref) {
    final primary = switch (cause) {
      ConversionOutcomeType.unreadable || ConversionOutcomeType.needsOcr => (
        'Choose a PDF instead',
        () => context.goNamed('upload'),
      ),
      ConversionOutcomeType.noTransactions ||
      ConversionOutcomeType.notAStatement => (
        'Choose another file',
        () => context.goNamed('upload'),
      ),
      _ => ('Try again', () => context.goNamed('upload')),
    };

    return [
      ElevatedButton(onPressed: primary.$2, child: Text(primary.$1)),
      const SizedBox(height: AppSpacing.sm),
      // The free sample is the best possible recovery — always offer it.
      OutlinedButton(
        onPressed: () async {
          await ref
              .read(conversionControllerProvider.notifier)
              .startMockConversion();
          if (context.mounted) context.goNamed('processing');
        },
        child: const Text('See a sample result'),
      ),
      if (cause == ConversionOutcomeType.noTransactions ||
          cause == ConversionOutcomeType.notAStatement) ...[
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () => context.goNamed('settings'),
          child: const Text('Request this bank'),
        ),
      ],
    ];
  }
}

/// Shown when a scan/photo came through with poor OCR legibility. A recoverable
/// decision — not a dead end: retake, upload the PDF, or convert anyway (which
/// parses the scan we already read, no re-shoot).
class _LowLegibilityCard extends ConsumerWidget {
  const _LowLegibilityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: ReconSnapColors.reviewSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.center_focus_weak_rounded,
                size: 28,
                color: ReconSnapColors.ochre,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: StatusPill(
              label: 'Scan legibility: Poor',
              tone: PillTone.warning,
              icon: Icons.warning_amber_rounded,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'This scan is hard to read',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Converting it may miss or misread rows. A clearer photo — or the '
            'original PDF — will reconcile far more reliably.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () => context.goNamed('upload'),
            child: const Text('Retake or upload the PDF'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () => ref
                .read(conversionControllerProvider.notifier)
                .continueWithLowLegibility(),
            child: const Text('Convert anyway'),
          ),
        ],
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
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ReconSnapColors.infoSurface,
              borderRadius: AppRadius.all(AppRadius.lg),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 24,
              color: ReconSnapColors.actionBlue,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'This statement is password-protected',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Enter the password to unlock the file. It is used only to open the '
            'PDF for this conversion.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
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
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.lock_open_rounded),
            label: const Text('Unlock and convert'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final password = _controller.text;
    if (password.isEmpty) return;
    ref.read(conversionControllerProvider.notifier).submitPassword(password);
  }
}
