import 'package:financelab_mobile/domain/models.dart';
import 'package:financelab_mobile/domain/summary.dart';
import 'package:financelab_mobile/ui/screens/analysis_screen.dart';
import 'package:financelab_mobile/ui/theme/app_theme.dart';
import 'package:financelab_mobile/ui/widgets/finance_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('analysis changes the shared chart period', (tester) async {
    final data = FinanceData(
      transactions: List.generate(
        8,
        (index) => Transaction(
          id: '$index',
          type: 'income',
          kind: 'income',
          date: '2026-${(index + 1).toString().padLeft(2, '0')}-01',
          category: 'Salário',
          subcategory: '',
          description: 'Entrada',
          amountCents: 10000,
        ),
      ),
    );
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final summary = FinanceSummary.fromData(data, '2026-08');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: AnalysisScreen(data: data, summary: summary),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Receitas e saídas por mês'), findsOneWidget);
    expect(find.text('Saldo acumulado das movimentações'), findsOneWidget);
    List<String> monthsInMonthlyChart() => tester
        .widget<MonthlyChart>(find.byType(MonthlyChart))
        .flows
        .map((flow) => flow.month)
        .toList();
    List<String> monthsInCumulativeChart() => tester
        .widget<CumulativeFlowChart>(find.byType(CumulativeFlowChart))
        .flows
        .map((flow) => flow.month)
        .toList();

    expect(monthsInMonthlyChart().first, '2026-03');
    expect(monthsInMonthlyChart().last, '2026-08');
    expect(monthsInCumulativeChart(), monthsInMonthlyChart());
    await tester.tap(find.text('3m'));
    await tester.pumpAndSettle();
    expect(monthsInMonthlyChart(), ['2026-06', '2026-07', '2026-08']);
    expect(monthsInCumulativeChart(), monthsInMonthlyChart());

    await tester.tap(find.text('12m'));
    await tester.pumpAndSettle();
    expect(monthsInMonthlyChart(), hasLength(12));
    expect(monthsInMonthlyChart().first, '2025-09');
    expect(monthsInMonthlyChart().last, '2026-08');
    expect(monthsInCumulativeChart(), monthsInMonthlyChart());
    expect(
      tester
          .widget<MonthlyChart>(find.byType(MonthlyChart))
          .flows
          .first
          .incomeCents,
      0,
    );
    expect(tester.takeException(), isNull);
  });
}
