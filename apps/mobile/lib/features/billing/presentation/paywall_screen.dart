import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/copy/trust_copy.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/reconsnap_theme.dart';
import '../../../app/widgets/app_components.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/billing/entitlements.dart';
import '../../../core/models/conversion_job.dart';
import '../../conversion/presentation/conversion_controller.dart';
import '../../conversion/presentation/result_summary.dart';
import 'entitlements_controller.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  static const routeName = 'paywall';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlements = ref.watch(entitlementsProvider);
    final controller = ref.read(entitlementsProvider.notifier);
    // Trigger the paywall *in context*: if there's a finished, reconciled result
    // waiting, lead with it — pay to take delivery of work you can already see
    // is good. The strongest, fairest conversion driver.
    final job = ref.watch(conversionControllerProvider).activeJob;

    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            SoftCard(
              child: Row(
                children: [
                  const BrandMark(size: 44),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entitlements.isPro
                              ? 'You are on Pro'
                              : job != null && !entitlements.canConvert
                              ? 'Unlock to export'
                              : 'Get more conversions',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _leadCopy(entitlements, job),
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

  String _leadCopy(Entitlements entitlements, ConversionJob? job) {
    if (entitlements.isPro) return 'Unlimited statement conversions.';
    if (job != null && !entitlements.canConvert) {
      return 'Your ${job.bank.name} statement is converted'
          '${job.fullyReconciled ? ' and reconciled' : ''}. '
          "You've used all ${Entitlements.freeAllowance} free conversions — "
          'unlock to export it.';
    }
    return '${entitlements.availableCredits} conversion'
        '${entitlements.availableCredits == 1 ? '' : 's'} left. '
        'Convert more with a pack or go unlimited.';
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
      (Icons.fact_check_outlined, TrustCopy.reconcileGuarantee),
      (Icons.grid_on_rounded, 'Export to Excel, QuickBooks, Xero, OFX & CSV'),
      (Icons.shield_outlined, TrustCopy.short),
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
              ? ReconSnapColors.terracotta
              : ReconSnapColors.border,
          width: highlight ? 1.6 : 1,
        ),
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
                              tone: PillTone.info,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        product.subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (product.savingsLabel != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          product.savingsLabel!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: ReconSnapColors.mossDeep,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
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
