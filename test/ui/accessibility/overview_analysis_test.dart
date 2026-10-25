import 'package:financelab_mobile/domain/models.dart';
import 'package:financelab_mobile/domain/summary.dart';
import 'package:financelab_mobile/ui/screens/analysis_screen.dart';
import 'package:financelab_mobile/ui/screens/overview_screen.dart';
import 'package:financelab_mobile/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final data = FinanceData(
    transactions: [
      const Transaction(
        id: 't1',
        type: 'expense',
        kind: 'expense',
        date: '2026-10-01',
        category: 'Moradia',
        subcategory: '',
        description: 'Aluguel',
        amountCents: 120000,
      ),
      const Transaction(
        id: 't2',
        type: 'expense',
        kind: 'expense',
        date: '2026-10-02',
        category: 'Alimentação',
        subcategory: '',
        description: 'Mercado',
        amountCents: 45000,
      ),
    ],
  );

  Widget app(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    home: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2)),
      child: child,
    ),
  );

  testWidgets('overview remains scrollable and readable with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      app(
        OverviewScreen(
          data: data,
          summary: FinanceSummary.fromData(data, '2026-10'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saldo do mês'), findsOneWidget);
    expect(find.text('Despesas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('metric cards expose a complete financial announcement', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      app(
        OverviewScreen(
          data: data,
          summary: FinanceSummary.fromData(data, '2026-10'),
        ),
      ),
    );
    expect(
      find.bySemanticsLabel(RegExp(r'Saldo do mês:.*Receitas menos despesas')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('analysis keeps category and amount together with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      app(
        AnalysisScreen(
          data: data,
          summary: FinanceSummary.fromData(data, '2026-10'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Moradia', skipOffstage: false), findsOneWidget);
    expect(
      find.textContaining(r'R$ 1.200,00', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Alimentação', skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
