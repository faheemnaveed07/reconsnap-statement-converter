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
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.status == ConversionStatus.failed)
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 54,
                      color: ReconSnapColors.riskRed,
                    )
                  else
                    const SizedBox(
                      width: 54,
                      height: 54,
                      child: CircularProgressIndicator(strokeWidth: 5),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    state.status == ConversionStatus.failed
                        ? 'Conversion failed'
                        : 'Reading statement structure',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.status == ConversionStatus.failed
                        ? state.errorMessage ?? 'Please try again.'
                        : 'ReconSnap is matching the bank template, extracting rows, and preparing validation checks.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ReconSnapColors.mutedInk,
                      height: 1.4,
                    ),
                  ),
                  if (state.status == ConversionStatus.failed) ...[
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () => context.goNamed('upload'),
                      child: const Text('Try another file'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
