class SubscriptionPlan {
  const SubscriptionPlan({
    required this.name,
    required this.monthlyPriceLabel,
    required this.pageAllowance,
    required this.description,
  });

  final String name;
  final String monthlyPriceLabel;
  final int pageAllowance;
  final String description;
}

const starterPlan = SubscriptionPlan(
  name: 'Starter',
  monthlyPriceLabel: r'$9.99/mo',
  pageAllowance: 50,
  description: 'For SMEs and occasional monthly statement conversion.',
);
