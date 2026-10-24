import 'models.dart';

class MonthlyFlow {
  const MonthlyFlow(
    this.month,
    this.incomeCents,
    this.expensesCents,
    this.contributionsCents,
  );
  final String month;
  final int incomeCents, expensesCents, contributionsCents;
  int get balanceCents => incomeCents - expensesCents;
}

class BudgetProgress {
  const BudgetProgress(this.category, this.limitCents, this.spentCents);
  final String category;
  final int limitCents, spentCents;
  int get remainingCents => limitCents - spentCents;
  double get usage => limitCents > 0 ? spentCents / limitCents : 0;
}

class FinanceSummary {
  final String monthKey;
  final int incomeCents,
      expensesCents,
      livingExpensesCents,
      contributionsCents,
      cashBalanceCents,
      portfolioCents,
      investedCents,
      monthlyYieldCents,
      projectedLivingExpensesCents;
  final Map<String, int> categoryCents, subcategoryCents;
  final List<MonthlyFlow> monthlyFlows;
  final List<BudgetProgress> budgetProgress;
  final List<String> alerts;
  final int transactionCount;
  int get portfolioGainCents => portfolioCents - investedCents;
  int get netWorthCents => cashBalanceCents + portfolioCents;
  int get projectedCashBalanceCents =>
      incomeCents - contributionsCents - projectedLivingExpensesCents;
  double? get savingsRate =>
      incomeCents > 0 ? cashBalanceCents / incomeCents : null;
  double? get emergencyCoverageMonths => livingExpensesCents > 0
      ? emergencySavedCents / livingExpensesCents
      : null;
  double? get portfolioReturnRate =>
      investedCents > 0 ? portfolioGainCents / investedCents : null;
  final int emergencySavedCents, emergencyTargetCents;
  FinanceSummary({
    required this.monthKey,
    required this.incomeCents,
    required this.expensesCents,
    required this.livingExpensesCents,
    required this.contributionsCents,
    required this.cashBalanceCents,
    required this.portfolioCents,
    required this.investedCents,
    required this.monthlyYieldCents,
    required this.projectedLivingExpensesCents,
    required this.categoryCents,
    required this.subcategoryCents,
    required this.monthlyFlows,
    required this.budgetProgress,
    required this.alerts,
    required this.transactionCount,
    required this.emergencySavedCents,
    required this.emergencyTargetCents,
  });

  factory FinanceSummary.fromData(
    FinanceData d,
    String month, {
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    var i = 0, e = 0, c = 0;
    final cats = <String, int>{};
    final subcats = <String, int>{};
    final months = <String, List<int>>{};
    var count = 0;
    for (final t in d.transactions) {
      final key = t.date.length >= 7 ? t.date.substring(0, 7) : '';
      if (RegExp(r'^\d{4}-\d{2}$').hasMatch(key)) {
        final totals = months.putIfAbsent(key, () => [0, 0, 0]);
        if (t.type == 'income') totals[0] += t.amountCents;
        if (t.type == 'expense') totals[1] += t.amountCents;
        if (t.kind == 'contribution') totals[2] += t.amountCents;
      }
      if (key != month) continue;
      count++;
      if (t.type == 'income') i += t.amountCents;
      if (t.type == 'expense') e += t.amountCents;
      if (t.kind == 'contribution') c += t.amountCents;
      if (t.type == 'expense' && t.kind != 'contribution') {
        cats[t.category] = (cats[t.category] ?? 0) + t.amountCents;
        final subcategory = t.subcategory.trim().isEmpty
            ? t.category
            : t.subcategory.trim();
        subcats[subcategory] = (subcats[subcategory] ?? 0) + t.amountCents;
      }
    }
    final p = d.funds.fold(0, (s, f) => s + f.currentCents),
        inv = d.funds.fold(0, (s, f) => s + f.investedCents);
    final yieldCents = d.funds.fold(0, (s, f) => s + f.monthlyYieldCents);
    final budgets = [
      for (final b in d.budgets)
        if (b.monthlyLimitCents > 0)
          BudgetProgress(
            b.category,
            b.monthlyLimitCents,
            cats[b.category] ?? 0,
          ),
    ]..sort((a, b) => b.usage.compareTo(a.usage));
    final flows = [
      for (final entry in months.entries)
        MonthlyFlow(entry.key, entry.value[0], entry.value[1], entry.value[2]),
    ]..sort((a, b) => a.month.compareTo(b.month));
    final currentMonth =
        '${today.year}-${today.month.toString().padLeft(2, '0')}';
    final living = e - c;
    final projectedLiving = month == currentMonth
        ? (living * DateTime(today.year, today.month + 1, 0).day / today.day)
              .round()
        : living;
    final alerts = <String>[];
    if (i - e < 0) alerts.add('O saldo do mês está negativo.');
    if (d.goals.monthlyBudgetCents > 0 && living > d.goals.monthlyBudgetCents) {
      alerts.add('Os gastos de consumo ultrapassaram o limite mensal.');
    }
    if (budgets.any((b) => b.usage >= 1)) {
      alerts.add('Há categorias acima do orçamento.');
    } else if (budgets.any((b) => b.usage >= .8)) {
      alerts.add('Há categorias próximas do limite.');
    }
    if (month == currentMonth && i - c - projectedLiving < 0) {
      alerts.add('No ritmo atual, o mês pode fechar com saldo negativo.');
    }
    return FinanceSummary(
      monthKey: month,
      incomeCents: i,
      expensesCents: e,
      livingExpensesCents: living,
      contributionsCents: c,
      cashBalanceCents: i - e,
      portfolioCents: p,
      investedCents: inv,
      monthlyYieldCents: yieldCents,
      projectedLivingExpensesCents: projectedLiving,
      categoryCents: cats,
      subcategoryCents: subcats,
      monthlyFlows: flows,
      budgetProgress: budgets,
      alerts: alerts,
      transactionCount: count,
      emergencySavedCents: d.goals.emergencySavedCents,
      emergencyTargetCents: d.goals.emergencyFundCents,
    );
  }
}
