import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/reconsnap_theme.dart';
import '../../../app/widgets/app_components.dart';
import '../../../core/models/conversion_job.dart';
import '../../../core/models/subscription_plan.dart';
import 'conversion_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routeName = 'home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            const BrandMark(size: 30, radius: AppRadius.sm),
            const SizedBox(width: 10),
            Text(
              'ReconSnap',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'History',
            onPressed: () => context.pushNamed('history'),
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.pushNamed('settings'),
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            const _HeroPanel(),
            const SizedBox(height: AppSpacing.md),
            const _TrustRow(),
            const SizedBox(height: AppSpacing.md),
            const _CreditPanel(),
            const SizedBox(height: AppSpacing.xxl),
            SectionHeader(
              title: 'Recent conversions',
              action: state.history.isEmpty
                  ? null
                  : TextButton(
                      onPressed: () => context.pushNamed('history'),
                      child: const Text('See all'),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (state.history.isEmpty)
              const _EmptyHistory()
            else
              ...state.history
                  .take(4)
                  .map(
                    (job) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _HistoryTile(job: job),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ReconSnapColors.heroGradient,
        borderRadius: AppRadius.all(AppRadius.xl),
        boxShadow: AppShadows.raised,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.all(AppRadius.xl),
        child: Stack(
          children: [
            // Integrated graphic pattern + radial glow for depth.
            const Positioned.fill(
              child: CustomPaint(painter: _HeroPatternPainter()),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StatusPill(
                    label: 'Balance-validated exports',
                    tone: PillTone.success,
                    icon: Icons.verified_rounded,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Bank PDFs to accountant-ready files',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Upload a statement, review extracted rows, run balance checks, and export clean CSV files.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.all(AppRadius.md),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => context.pushNamed('upload'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: ReconSnapColors.ink900,
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Convert statement'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A restrained "integrated graphic pattern": a soft corner glow plus faint
/// concentric rings — depth without noise, on the navy hero surface.
class _HeroPatternPainter extends CustomPainter {
  const _HeroPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width - 24, 18);

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.7));
    canvas.drawRect(Offset.zero & size, glow);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.06);
    for (final r in [60.0, 110.0, 168.0, 232.0]) {
      canvas.drawCircle(center, r, ring);
    }
  }

  @override
  bool shouldRepaint(_HeroPatternPainter oldDelegate) => false;
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        StatusPill(label: 'Balance validation', icon: Icons.fact_check_rounded),
        StatusPill(label: 'Password PDFs', icon: Icons.lock_outline_rounded),
        StatusPill(label: 'Editable review', icon: Icons.edit_note_rounded),
      ],
    );
  }
}

class _CreditPanel extends StatelessWidget {
  const _CreditPanel();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: () => context.pushNamed('paywall'),
      child: Row(
        children: [
          // Brand-gradient seal — the premium-tier marker.
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: ReconSnapColors.heroGradient,
              borderRadius: AppRadius.all(AppRadius.md),
              boxShadow: AppShadows.soft,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${starterPlan.name} plan',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const StatusPill(label: 'Preview', tone: PillTone.info),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${starterPlan.pageAllowance} pages/month · ${starterPlan.monthlyPriceLabel}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const StatusPill(
            label: 'Upgrade',
            tone: PillTone.success,
            icon: Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: ReconSnapColors.subtle,
              borderRadius: AppRadius.all(AppRadius.md),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 28,
              color: ReconSnapColors.mutedInk,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No conversions yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your converted statements will appear here with validation status and export options.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.job});

  final ConversionJob job;

  @override
  Widget build(BuildContext context) {
    final passed = job.validationReport.isPassed;

    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: () => context.pushNamed('validation'),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: ReconSnapColors.subtle,
              borderRadius: AppRadius.all(AppRadius.sm),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: ReconSnapColors.ink700,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  '${job.bank.name} · ${job.transactions.length} rows',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusPill(
            label: passed ? 'Validated' : 'Review',
            tone: passed ? PillTone.success : PillTone.warning,
          ),
        ],
      ),
    );
  }
}
