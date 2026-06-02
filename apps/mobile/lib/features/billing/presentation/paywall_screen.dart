import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/reconsnap_theme.dart';
import '../../../app/widgets/app_components.dart';
import '../../../core/billing/billing_service.dart';
import 'entitlements_controller.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  static const routeName = 'paywall';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlements = ref.watch(entitlementsProvider);
    final controller = ref.read(entitlementsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            SoftCard(
              child: Row(
                children: [
                  const BrandMark(),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entitlements.isPro
                              ? 'You are on Pro'
                              : 'Get more conversions',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entitlements.isPro
                              ? 'Unlimited statement conversions.'
                              : '${entitlements.availableCredits} conversion${entitlements.availableCredits == 1 ? '' : 's'} left. Convert more with a pack or go unlimited.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _Benefits(),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: 'Plans'),
            const SizedBox(height: AppSpacing.md),
            if (!entitlements.isPro)
              ...BillingProduct.values.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _ProductCard(
                    product: p,
                    highlight: p == BillingProduct.proYearly,
                    onTap: () => _buy(context, controller, p),
                  ),
                ),
              )
            else
              const _NoteTile(
                text:
                    'Thanks for supporting ReconSnap. Enjoy unlimited conversions.',
              ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () async {
                await controller.restorePurchases();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Purchases restored.')),
                  );
                }
              },
              child: const Text('Restore purchases'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buy(
    BuildContext context,
    EntitlementsController controller,
    BillingProduct product,
  ) async {
    // The real store purchase sheet slots in here behind BillingService; the
    // local implementation grants the entitlement immediately.
    await controller.purchase(product);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${product.title} unlocked.')));
    if (context.canPop()) context.pop();
  }
}

class _Benefits extends StatelessWidget {
  const _Benefits();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.shield_outlined, 'Processed on your device — never uploaded'),
      (
        Icons.fact_check_outlined,
        'Balance-validated, low-confidence rows flagged',
      ),
      (Icons.grid_on_rounded, 'Export to CSV and Excel'),
    ];
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          for (final (icon, text) in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: ReconSnapColors.accentGreenDark),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onTap,
    this.highlight = false,
  });

  final BillingProduct product;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ReconSnapColors.card,
        borderRadius: AppRadius.all(AppRadius.lg),
        border: Border.all(
          color: highlight
              ? ReconSnapColors.accentGreen
              : ReconSnapColors.border,
          width: highlight ? 1.6 : 1,
        ),
        boxShadow: highlight ? AppShadows.card : null,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            product.title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          if (highlight) ...[
                            const SizedBox(width: AppSpacing.sm),
                            const StatusPill(
                              label: 'Best value',
                              tone: PillTone.success,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        product.subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  product.priceLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
