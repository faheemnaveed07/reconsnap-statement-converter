import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/copy/trust_copy.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/reconsnap_theme.dart';
import '../../../app/widgets/app_components.dart';
import '../../../core/services/first_run_store.dart';
import '../../conversion/presentation/conversion_controller.dart';

final firstRunStoreProvider = Provider((ref) => FirstRunStore());

/// Whether onboarding has been completed. Overridden at startup in `main()`
/// with the persisted value so the right initial route is chosen with no flash.
final onboardingSeenProvider = Provider<bool>((ref) => false);

class _Slide {
  const _Slide(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const routeName = 'onboarding';

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      Icons.document_scanner_rounded,
      'Bank PDFs to accountant-ready files',
      'Convert statements to CSV, Excel, QuickBooks/Xero and OFX in seconds.',
    ),
    _Slide(
      Icons.fact_check_outlined,
      'Checked, not guessed',
      TrustCopy.reconcileGuarantee,
    ),
    _Slide(Icons.shield_outlined, 'Private by design', TrustCopy.oneLine),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(firstRunStoreProvider).markSeen();
    if (mounted) context.go('/');
  }

  /// Lead with proof: run the sample conversion and drop the user straight into
  /// a real, reconciled Result — the strongest possible first impression.
  Future<void> _finishWithDemo() async {
    await ref.read(firstRunStoreProvider).markSeen();
    await ref.read(conversionControllerProvider.notifier).startMockConversion();
    if (mounted) {
      context.go('/');
      context.pushNamed('processing');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.page,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _Dots(count: _slides.length, active: _page),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLast) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(isLast ? 'Get started' : 'Next'),
                ),
              ),
              if (isLast) ...[
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: _finishWithDemo,
                  child: const Text('See a sample result first'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const BrandMark(size: 72, radius: 22),
        const SizedBox(height: AppSpacing.xl),
        Icon(slide.icon, size: 48, color: ReconSnapColors.accentGreenDark),
        const SizedBox(height: AppSpacing.lg),
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          slide.body,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});
  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == active
                  ? ReconSnapColors.accentGreen
                  : ReconSnapColors.border,
              borderRadius: AppRadius.all(AppRadius.pill),
            ),
          ),
      ],
    );
  }
}
