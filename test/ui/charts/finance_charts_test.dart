import 'package:financelab_mobile/domain/models.dart';
import 'package:financelab_mobile/domain/summary.dart';
import 'package:financelab_mobile/ui/screens/analysis_screen.dart';
import 'package:financelab_mobile/ui/screens/overview_screen.dart';
import 'package:financelab_mobile/ui/widgets/finance_charts.dart';
import 'package:financelab_mobile/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final data = FinanceData(
    transactions: [
      const Transaction(
        id: 'income',
        type: 'income',
        kind: 'income',
        date: '2026-10-01',
        category: 'Salário',
        subcategory: '',
        description: 'Salário',
        amountCents: 650000,
      ),
      const Transaction(
        id: 'home',
        type: 'expense',
        kind: 'expense',
        date: '2026-10-02',
        category: 'Moradia',
        subcategory: '',
        description: 'Aluguel',
        amountCents: 180000,
      ),
      const Transaction(
        id: 'food',
        type: 'expense',
        kind: 'expense',
        date: '2026-09-02',
        category: 'Alimentação',
        subcategory: '',
        description: 'Mercado',
        amountCents: 68000,
      ),
    ],
  );

  Widget app(Widget child) => MaterialApp(
    theme: AppTheme.dark(),
    home: MediaQuery(
      data: const MediaQueryData(
        size: Size(320, 700),
        textScaler: TextScaler.linear(2),
      ),
      child: child,
    ),
  );

  testWidgets('analysis exposes chart values and remains scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final summary = FinanceSummary.fromData(data, '2026-10');
    await tester.pumpWidget(app(AnalysisScreen(data: data, summary: summary)));
    await tester.pumpAndSettle();

    expect(find.text('Gráfico de despesas de consumo'), findsOneWidget);
    expect(find.text('Moradia'), findsWidgets);
    expect(find.text('Histórico mensal', skipOffstage: false), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(RegExp('Gráfico de despesas por categoria')),
      findsOneWidget,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(RegExp('Gráfico mensal de receitas')),
      findsOneWidget,
    );
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('overview includes compact monthly chart without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final summary = FinanceSummary.fromData(data, '2026-10');
    await tester.pumpWidget(app(OverviewScreen(data: data, summary: summary)));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('Últimos meses', skipOffstage: false), findsOneWidget);
    expect(find.text('Receitas', skipOffstage: false), findsWidgets);
    expect(
      find.text('Saídas (inclui aportes)', skipOffstage: false),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'category chart groups smaller categories and keeps full totals',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final entries = [
        for (var i = 0; i < 7; i++) MapEntry('Categoria $i', (7 - i) * 1000),
      ];
      await tester.pumpWidget(
        app(SingleChildScrollView(child: CategoryChart(entries: entries))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Outras categorias'), findsOneWidget);
      final semantics = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel(RegExp(r'Outras categorias: R\$ 30,00, 11%')),
        findsOneWidget,
      );
      semantics.dispose();
      expect(
        find.text(
          'As categorias menores foram agrupadas em “Outras categorias”.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('monthly chart exposes month labels and wraps legend', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      app(
        SingleChildScrollView(
          child: MonthlyChart(
            flows: const [
              MonthlyFlow('2026-09', 10000, 4000, 0),
              MonthlyFlow('2026-10', 20000, 12000, 2000),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saídas (inclui aportes)'), findsOneWidget);
    expect(find.text('09'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    final chartPaint = find.descendant(
      of: find.byType(MonthlyChart),
      matching: find.byType(CustomPaint),
    );
    expect(tester.getSize(chartPaint).height, greaterThan(100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('budget use includes a graphical percentage', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final budgeted = data.copyWith(
      budgets: const [
        Budget(
          id: 'housing-budget',
          category: 'Moradia',
          monthlyLimitCents: 360000,
        ),
      ],
    );
    await tester.pumpWidget(
      app(
        AnalysisScreen(
          data: budgeted,
          summary: FinanceSummary.fromData(budgeted, '2026-10'),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Uso dos orçamentos'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('50%'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is LinearProgressIndicator && widget.value == 0.5,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
