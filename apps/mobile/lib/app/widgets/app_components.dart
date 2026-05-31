import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/reconsnap_theme.dart';

/// The ReconSnap logo mark: a gradient rounded square with a scan glyph.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44, this.radius = AppRadius.md});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: ReconSnapColors.heroGradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.card,
      ),
      child: Icon(
        Icons.document_scanner_rounded,
        color: Colors.white,
        size: size * 0.52,
      ),
    );
  }
}

/// A white surface with a hairline border and a soft, layered shadow — the
/// premium card used for hero and primary content blocks.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final decorated = Container(
      decoration: BoxDecoration(
        color: ReconSnapColors.card,
        borderRadius: AppRadius.all(AppRadius.lg),
        border: Border.all(color: ReconSnapColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return decorated;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.all(AppRadius.lg),
        onTap: onTap,
        child: decorated,
      ),
    );
  }
}

enum PillTone { neutral, success, warning, danger, info }

/// Compact status/label pill with semantic colouring.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.tone = PillTone.neutral, this.icon});

  final String label;
  final PillTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (tone) {
      PillTone.success => (ReconSnapColors.accentGreenDark, ReconSnapColors.successSurface),
      PillTone.warning => (ReconSnapColors.warningAmber, ReconSnapColors.warningSurface),
      PillTone.danger => (ReconSnapColors.riskRed, ReconSnapColors.riskSurface),
      PillTone.info => (ReconSnapColors.actionBlue, Color(0xFFEAF1FE)),
      PillTone.neutral => (ReconSnapColors.ink700, ReconSnapColors.subtle),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.all(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 12,
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
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}
