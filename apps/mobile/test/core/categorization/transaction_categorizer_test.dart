import 'package:flutter_test/flutter_test.dart';
import 'package:reconsnap_statement_converter/core/categorization/transaction_categorizer.dart';
import 'package:reconsnap_statement_converter/core/models/statement_transaction.dart';

StatementTransaction _tx(String description, {double? debit, double? credit}) {
  return StatementTransaction(
    id: 'x',
    date: DateTime(2024, 6, 20),
    description: description,
    debit: debit,
    credit: credit,
  );
}

void main() {
  const c = TransactionCategorizer();

  test('keyword rules map common GCC descriptions', () {
    expect(
      c.categorize(_tx('CARD NO.443913 METRO TAXI DUBAI', debit: 22)),
      TransactionCategories.travel,
    );
    expect(
      c.categorize(_tx('GOOGLE*GOOGLE STORAGE', debit: 7.64)),
      TransactionCategories.software,
    );
    expect(
      c.categorize(_tx('LuluHypermarket QUSAIS', debit: 23.10)),
      TransactionCategories.groceries,
    );
    expect(
      c.categorize(_tx('IPI TT REF: MBA000', credit: 525)),
      TransactionCategories.transfers,
    );
    expect(
      c.categorize(_tx('ATM withdrawal', debit: 600)),
      TransactionCategories.cash,
    );
    expect(
      c.categorize(_tx('Monthly service charge', debit: 25)),
      TransactionCategories.bankCharges,
    );
  });

  test('salary credit is income, payroll debit is payroll', () {
    expect(
      c.categorize(_tx('Salary credit', credit: 3000)),
      TransactionCategories.income,
    );
    expect(
      c.categorize(_tx('Payroll run WPS', debit: 3000)),
      TransactionCategories.salaries,
    );
  });

  test('unknown falls back by direction', () {
    expect(
      c.categorize(_tx('Mystery debit', debit: 10)),
      TransactionCategories.uncategorized,
    );
    expect(
      c.categorize(_tx('Mystery deposit', credit: 10)),
      TransactionCategories.income,
    );
  });
}
