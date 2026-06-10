import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/reconsnap_theme.dart';

/// The ReconSnap mark — a serif monogram on paper with a hairline border and a
/// single terracotta check-rule beneath it (the "verified" signature device).
/// The gradient wallet glyph is retired: the brand's strongest asset is its
/// name set well, in ink, on paper. For the full lockup use [Wordmark].
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 36, this.radius = AppRadius.md});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ReconSnapColors.paper,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: ReconSnapColors.outline),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'R',
            style: ReconSnapTheme.serif(
              fontSize: size * 0.5,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          SizedBox(height: size * 0.06),
          Container(
            width: size * 0.36,
            height: size * 0.055,
            color: ReconSnapColors.terracotta,
          ),
        ],
      ),
    );
  }
}

/// The full ReconSnap wordmark — serif, ink on paper, with a small terracotta
/// check device. The brand's primary lockup (Home, onboarding, paywall header).
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.fontSize = 22, this.showCheck = true});

  final double fontSize;
  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'ReconSnap',
          style: ReconSnapTheme.serif(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            height: 1,
          ),
        ),
        if (showCheck) ...[
          SizedBox(width: fontSize * 0.18),
          Icon(
            Icons.check_rounded,
            size: fontSize * 0.62,
            color: ReconSnapColors.terracotta,
          ),
        ],
      ],
    );
  }
}

/// A paper surface with a hairline border — the core data card. Flat by default
/// (depth comes from the border + the paper); [elevated] is reserved for
/// floating modal surfaces only.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.radius = AppRadius.md,
    this.color = ReconSnapColors.card,
    this.borderColor = ReconSnapColors.border,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double radius;
  final Color color;
  final Color borderColor;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final decorated = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: elevated ? AppShadows.raised : null,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return decorated;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: decorated,
      ),
    );
  }
}

/// The trust traffic-light. Names are kept stable; the colours map to the
/// editorial palette: [success] = moss (verified), [warning] = ochre (needs
/// review), [danger] = brick (failed), [info] = terracotta (brand accent),
/// [neutral] = ink tint.
enum PillTone { neutral, success, warning, danger, info }

/// Compact status/label pill with semantic colouring — pill-shaped to
/// distinguish it from interactive buttons. Status colour always pairs with the
/// label text (and an optional icon), never colour alone.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.tone = PillTone.neutral,
    this.icon,
  });

  final String label;
  final PillTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (tone) {
      PillTone.success => (
        ReconSnapColors.mossDeep,
        ReconSnapColors.verifiedSurface,
      ),
      PillTone.warning => (
        ReconSnapColors.ochre,
        ReconSnapColors.reviewSurface,
      ),
      PillTone.danger => (ReconSnapColors.brick, ReconSnapColors.failSurface),
      PillTone.info => (
        ReconSnapColors.terracotta,
        ReconSnapColors.accentSurface,
      ),
      PillTone.neutral => (ReconSnapColors.ink700, ReconSnapColors.container),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.all(AppRadius.pill),
        border: Border.all(color: fg.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section title with an optional trailing action (e.g. "See all").
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        ?action,
      ],
    );
  }
}

/// A tracked uppercase eyebrow — section metadata above a title.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = ReconSnapColors.mutedInk});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: ReconSnapTheme.eyebrow(color: color),
    );
  }
}

/// Monospaced figure — for currency, transaction IDs, dates and any numeric
/// value that should align in a column.
class MonoText extends StatelessWidget {
  const MonoText(
    this.text, {
    super.key,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w500,
    this.color = ReconSnapColors.ink900,
    this.textAlign,
  });

  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: ReconSnapTheme.mono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}

/// A circular ring with a fraction in the centre — the per-conversion
/// "rows auto-verified" indicator. The label states the denominator so the
/// number can be decomposed; moss because it represents verification.
class TrustRing extends StatelessWidget {
  const TrustRing({
    super.key,
    required this.percent,
    this.size = 128,
    this.stroke = 10,
    this.color = ReconSnapColors.mossDeep,
    this.centerText,
    this.label = 'Rows auto-verified',
  });

  /// 0.0–1.0
  final double percent;
  final double size;
  final double stroke;
  final Color color;

  /// Optional override for the centre figure (e.g. "44/47"). Falls back to a
  /// percentage when null.
  final String? centerText;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(
              percent: percent.clamp(0, 1),
              stroke: stroke,
              color: color,
              track: ReconSnapColors.containerHigh,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerText ?? '${(percent * 100).round()}%',
                style: ReconSnapTheme.mono(
                  fontSize: centerText != null ? 22 : 26,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: size * 0.82,
                child: Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: ReconSnapTheme.eyebrow(fontSize: 9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.percent,
    required this.stroke,
    required this.color,
    required this.track,
  });

  final double percent;
  final double stroke;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * percent,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.percent != percent || old.color != color;
}

/// State of a single step in a vertical progress list.
enum StepStatus { done, active, pending }

class ProcessStep {
  const ProcessStep({
    required this.title,
    required this.subtitle,
    required this.state,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final StepStatus state;
  final IconData icon;
}

/// A vertical, connected step list. Each step's [state] is driven by the real
/// pipeline — done flips when a stage returns; there is no fabricated motion.
class StepProgressList extends StatelessWidget {
  const StepProgressList({super.key, required this.steps});

  final List<ProcessStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          _StepRow(step: steps[i], isLast: i == steps.length - 1),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.isLast});

  final ProcessStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final (bubbleBg, bubbleFg, connector) = switch (step.state) {
      StepStatus.done => (
        ReconSnapColors.verifiedSurface,
        ReconSnapColors.mossDeep,
        ReconSnapColors.mossDeep,
      ),
      StepStatus.active => (
        ReconSnapColors.ink,
        Colors.white,
        ReconSnapColors.border,
      ),
      StepStatus.pending => (
        ReconSnapColors.container,
        ReconSnapColors.mutedInk,
        ReconSnapColors.border,
      ),
    };
    final dim = step.state == StepStatus.pending;

    return Opacity(
      opacity: dim ? 0.55 : 1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bubbleBg,
                  shape: BoxShape.circle,
                  border: step.state == StepStatus.active
                      ? Border.all(color: ReconSnapColors.ink, width: 1)
                      : null,
                ),
                child: step.state == StepStatus.active
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Icon(
                        step.state == StepStatus.done
                            ? Icons.check_rounded
                            : step.icon,
                        size: 17,
                        color: bubbleFg,
                      ),
              ),
              if (!isLast) Container(width: 2, height: 36, color: connector),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  step.subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (!isLast) const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
