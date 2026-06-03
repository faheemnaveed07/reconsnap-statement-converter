import '../models/statement_transaction.dart';

/// The accounting categories ReconSnap assigns. Kept small and bookkeeping-
/// friendly; the user can re-assign any row.
class TransactionCategories {
  TransactionCategories._();

  static const income = 'Income';
  static const transfers = 'Transfers';
  static const salaries = 'Salaries & Payroll';
  static const bankCharges = 'Bank Charges & Fees';
  static const software = 'Software & Subscriptions';
  static const travel = 'Travel & Transport';
  static const meals = 'Meals & Dining';
  static const groceries = 'Groceries & Supplies';
  static const utilities = 'Utilities & Telecom';
  static const rent = 'Rent & Lease';
  static const taxes = 'Taxes';
  static const cash = 'Cash & ATM';
  static const uncategorized = 'Uncategorized';

  /// All categories, in the order shown in the picker.
  static const all = [
    income,
    transfers,
    salaries,
    bankCharges,
    software,
    travel,
    meals,
    groceries,
    utilities,
    rent,
    taxes,
    cash,
    uncategorized,
  ];
}

/// Assigns an accounting category from the transaction description using ordered
/// keyword rules (first match wins, specific → general). Deterministic and
/// on-device — no AI call, no network. A reasonable first guess the user edits;
/// it is never treated as authoritative.
class TransactionCategorizer {
  const TransactionCategorizer();

  // Ordered: earlier rules win. Keywords are matched against the lower-cased
  // description padded with spaces, so ' du ' won't match "dubai".
  static const _rules = <(String, List<String>)>[
    (TransactionCategories.cash, ['atm', 'cash withdrawal', 'cash wdl']),
    (
      TransactionCategories.bankCharges,
      ['fee', 'charge', 'commission', 'vat', 'service charge'],
    ),
    (TransactionCategories.salaries, ['salary', 'payroll', 'wages', 'wps']),
    (
      TransactionCategories.transfers,
      [
        'transfer',
        'tt ref',
        'mobile banking',
        'imps',
        'neft',
        'rtgs',
        'swift',
        'remittance',
        'inward',
        'outward',
      ],
    ),
    (
      TransactionCategories.software,
      [
        'google',
        'apple.com',
        'microsoft',
        'adobe',
        'aws',
        'netflix',
        'spotify',
        'subscription',
        'openai',
        'github',
      ],
    ),
    (
      TransactionCategories.travel,
      [
        'taxi',
        'uber',
        'careem',
        'metro',
        'fuel',
        'petrol',
        'adnoc',
        'enoc',
        'airline',
        'flight',
      ],
    ),
    (
      TransactionCategories.meals,
      [
        'restaurant',
        'cafe',
        'coffee',
        'starbucks',
        'mcdonald',
        'talabat',
        'deliveroo',
        'dining',
      ],
    ),
    (
      TransactionCategories.groceries,
      [
        'lulu',
        'carrefour',
        'spinneys',
        'supermarket',
        'hypermarket',
        'grocery',
        'union coop',
        'office supplies',
        'stationery',
      ],
    ),
    (
      TransactionCategories.utilities,
      [
        'dewa',
        'sewa',
        'etisalat',
        ' du ',
        'electricity',
        'water bill',
        'internet',
        'telecom',
      ],
    ),
    (TransactionCategories.rent, ['rent', 'lease', 'ejari', 'tenancy']),
    (
      TransactionCategories.taxes,
      ['tax payment', 'vat payment', 'corporate tax', 'zakat'],
    ),
  ];

  String categorize(StatementTransaction t) {
    final haystack = ' ${t.description.toLowerCase()} ';
    final isCredit = (t.credit ?? 0) != 0;

    for (final (category, keywords) in _rules) {
      if (keywords.any(haystack.contains)) {
        // Incoming money that merely mentions "salary" is income, not payroll.
        if (category == TransactionCategories.salaries && isCredit) {
          return TransactionCategories.income;
        }
        return category;
      }
    }
    return isCredit
        ? TransactionCategories.income
        : TransactionCategories.uncategorized;
  }
}
