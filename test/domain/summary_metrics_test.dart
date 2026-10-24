import 'package:flutter_test/flutter_test.dart';
import 'package:financelab_mobile/domain/models.dart';
import 'package:financelab_mobile/domain/summary.dart';

void main() {
  test(
    'summary separates consumption from contributions and projects month',
    () {
      const data = FinanceData(
        transactions: [
          Transaction(
            id: 'income',
            type: 'income',
            kind: 'income',
            date: '2026-10-01',
            category: 'Salário',
            subcategory: '',
            description: 'Salário',
            amountCents: 100000,
          ),
          Transaction(
            id: 'expense',
            type: 'expense',
            kind: 'expense',
            date: '2026-10-02',
            category: 'Casa',
            subcategory: 'Aluguel',
            description: 'Aluguel',
            amountCents: 20000,
          ),
          Transaction(
            id: 'contribution',
            type: 'expense',
            kind: 'contribution',
            date: '2026-10-03',
            category: 'Investimento',
            subcategory: '',
            description: 'Aporte',
            amountCents: 10000,
          ),
          Transaction(
            id: 'old',
            type: 'expense',
            kind: 'expense',
            date: '2026-09-01',
            category: 'Casa',
            subcategory: '',
            description: 'Aluguel',
            amountCents: 15000,
          ),
        ],
        budgets: [Budget(id: 'b', category: 'Casa', monthlyLimitCents: 25000)],
        funds: [
          Fund(
            id: 'f',
            name: 'Fundo',
            account: '',
            category: 'Renda fixa',
            benchmark: '',
            liquidity: '',
            investedCents: 30000,
            currentCents: 33000,
            monthlyYieldCents: 100,
          ),
        ],
        goals: Goals(emergencySavedCents: 40000),
      );
      final summary = FinanceSummary.fromData(
        data,
        '2026-10',
        now: DateTime(2026, 10, 10),
      );
      expect(summary.expensesCents, 30000);
      expect(summary.livingExpensesCents, 20000);
      expect(summary.contributionsCents, 10000);
      expect(summary.cashBalanceCents, 70000);
      expect(summary.projectedLivingExpensesCents, 62000);
      expect(summary.categoryCents['Casa'], 20000);
      expect(summary.subcategoryCents['Aluguel'], 20000);
      expect(summary.budgetProgress.single.usage, .8);
      expect(summary.monthlyFlows.length, 2);
      expect(summary.netWorthCents, 103000);
      expect(summary.portfolioGainCents, 3000);
      expect(summary.emergencyCoverageMonths, 2);
    },
  );
}
