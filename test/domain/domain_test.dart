import 'package:flutter_test/flutter_test.dart';
import 'package:financelab_mobile/domain/money.dart';
import 'package:financelab_mobile/domain/models.dart';
import 'package:financelab_mobile/domain/summary.dart';

void main() {
  test('money parses pt-BR precisely', () {
    expect(Money.tryParsePtBr('1.234,56'), 123456);
    expect(Money.tryParsePtBr('10,5'), 1050);
    expect(Money.tryParsePtBr('0,01'), 1);
    expect(Money.tryParsePtBr(Money.formatBr(-123456)), -123456);
    expect(Money.tryParsePtBr('abc'), isNull);
    expect(() => Money.parsePtBr('1,234'), throwsFormatException);
  });
  test('finance data JSON round trip', () {
    const data = FinanceData(
      transactions: [
        Transaction(
          id: 't',
          type: 'income',
          kind: 'income',
          date: '2026-10-01',
          category: 'Salário',
          subcategory: '',
          description: 'x',
          amountCents: 12345,
        ),
      ],
    );
    expect(
      FinanceData.fromJson(data.toJson()).transactions.single.amountCents,
      12345,
    );
  });
  test('rejects malformed amounts instead of replacing them with zero', () {
    const prefix =
        '{"financeData":{"transactions":[{"id":"t",'
        '"type":"expense","kind":"expense","date":"2026-10-01",'
        '"category":"Casa","subcategory":"","description":"Conta",'
        '"amount":';
    const suffix =
        '}],"funds":[],"budgets":[],"goals":{'
        '"monthlyBudget":0,"emergencyFund":0,"emergencySaved":0}}}';
    for (final amount in ['"indisponível"', '1.999', '-1']) {
      expect(
        () => FinanceData.fromImportJson('$prefix$amount$suffix'),
        throwsFormatException,
      );
    }
    expect(() => FinanceData.fromImportJson('{}'), throwsFormatException);
  });
  test('summary computes period KPIs', () {
    const data = FinanceData(
      transactions: [
        Transaction(
          id: '1',
          type: 'income',
          kind: 'income',
          date: '2026-10-01',
          category: 'Salário',
          subcategory: '',
          description: '',
          amountCents: 10000,
        ),
        Transaction(
          id: '2',
          type: 'expense',
          kind: 'expense',
          date: '2026-10-02',
          category: 'Casa',
          subcategory: '',
          description: '',
          amountCents: 2500,
        ),
      ],
    );
    final s = FinanceSummary.fromData(data, '2026-10');
    expect(s.incomeCents, 10000);
    expect(s.expensesCents, 2500);
    expect(s.cashBalanceCents, 7500);
    expect(s.categoryCents['Casa'], 2500);
  });
}
