import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:financelab_mobile/domain/models.dart';
import 'package:financelab_mobile/domain/summary.dart';
import 'package:financelab_mobile/ui/screens/analysis_screen.dart';
import 'package:financelab_mobile/ui/screens/overview_screen.dart';
import 'package:financelab_mobile/ui/theme/app_theme.dart';

void main() {
  testWidgets('overview shows an honest empty state', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const data = FinanceData();
    final summary = FinanceSummary.fromData(data, '2026-10');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: OverviewScreen(data: data, summary: summary),
      ),
    );
    expect(
      find.text('Ainda não há despesas de consumo neste mês.'),
      findsOneWidget,
    );
  });

  testWidgets('analysis renders categories from real data', (tester) async {
    const data = FinanceData(
      transactions: [
        Transaction(
          id: '1',
          type: 'expense',
          kind: 'expense',
          date: '2026-10-02',
          category: 'Moradia',
          subcategory: '',
          description: 'Aluguel',
          amountCents: 125000,
        ),
      ],
    );
    final summary = FinanceSummary.fromData(data, '2026-10');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: AnalysisScreen(data: data, summary: summary),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Moradia'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Moradia'), findsOneWidget);
    expect(find.text('R\$ 1.250,00'), findsOneWidget);
    expect(find.text('Sem despesas no período'), findsNothing);
  });
}
