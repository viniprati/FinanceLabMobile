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
    builder: (context, appChild) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: const TextScaler.linear(2)),
      child: appChild!,
    ),
    home: Scaffold(body: child),
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

    final semantics = tester.ensureSemantics();
    expect(
      find.descendant(
        of: find.byType(MonthlyChart),
        matching: find.bySemanticsLabel(RegExp('Receitas e saídas por mês')),
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Despesas por categoria'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(CategoryChart),
        matching: find.bySemanticsLabel(RegExp('Despesas por categoria')),
      ),
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
    expect(
      find.text('Receitas e saídas por mês', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Receitas', skipOffstage: false), findsWidgets);
    expect(find.text('Gastos de consumo', skipOffstage: false), findsWidgets);
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
    expect(find.text('Gastos de consumo'), findsOneWidget);
    expect(find.text('Aportes'), findsOneWidget);
    expect(find.text('09'), findsWidgets);
    expect(find.text('10'), findsWidgets);
    final chartPaint = find.descendant(
      of: find.byType(MonthlyChart),
      matching: find.byType(CustomPaint),
    );
    expect(tester.getSize(chartPaint.first).height, greaterThan(100));
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
        BudgetUseChart(
          budgets: FinanceSummary.fromData(budgeted, '2026-10').budgetProgress,
        ),
      ),
    );
    expect(find.text('50% do limite usado'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is LinearProgressIndicator && widget.value == 0.5,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('monthly bars expose selected month details by tap', (
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
              MonthlyFlow('2026-08', 10000, 2000, 0),
              MonthlyFlow('2026-09', 12000, 9000, 0),
              MonthlyFlow('2026-10', 20000, 5000, 0),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final plot = find
        .descendant(
          of: find.byType(MonthlyChart),
          matching: find.byType(CustomPaint),
        )
        .first;
    final rect = tester.getRect(plot);
    await tester.tapAt(Offset(rect.left + rect.width / 6, rect.center.dy));
    await tester.pumpAndSettle();
    expect(find.textContaining('2026-08:'), findsOneWidget);
    await tester.tapAt(Offset(rect.center.dx, rect.center.dy));
    await tester.pumpAndSettle();
    expect(find.textContaining('2026-09:'), findsOneWidget);
    await tester.tapAt(Offset(rect.right - rect.width / 6, rect.center.dy));
    await tester.pumpAndSettle();
    expect(find.textContaining('2026-10:'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Selecionar 2026-09'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2026-09:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cumulative chart includes negative movement and zero reference',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        app(
          SingleChildScrollView(
            child: CumulativeFlowChart(
              flows: const [
                MonthlyFlow('2026-09', 100, 500, 0),
                MonthlyFlow('2026-10', 900, 100, 0),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final semantics = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel(RegExp('não representa saldo bancário')),
        findsOneWidget,
      );
      expect(find.textContaining('R\$ 0,00'), findsOneWidget);
      semantics.dispose();
      final plot = find
          .descendant(
            of: find.byType(CumulativeFlowChart),
            matching: find.byType(CustomPaint),
          )
          .first;
      final rect = tester.getRect(plot);
      expect(rect.width, greaterThan(0));
      await tester.tapAt(Offset(rect.left + 2, rect.center.dy));
      await tester.pumpAndSettle();
      expect(find.text('2026-09: -R\$ 4,00'), findsOneWidget);
      await tester.tapAt(Offset(rect.right - 2, rect.center.dy));
      await tester.pumpAndSettle();
      expect(find.text('2026-10: R\$ 4,00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('fund distribution has fund semantics and current amounts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      app(
        SingleChildScrollView(
          child: FundDistributionChart(
            funds: const [
              Fund(
                id: '1',
                name: 'Reserva',
                account: '',
                category: 'Renda fixa',
                benchmark: '',
                liquidity: '',
                investedCents: 10000,
                currentCents: 12500,
                monthlyYieldCents: 0,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(RegExp('Valores atuais dos fundos')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp(r'R\$ 125,00')), findsWidgets);
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('fund distribution explains registered funds with zero value', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const FundDistributionChart(
          funds: [
            Fund(
              id: 'zero',
              name: 'Reserva',
              account: '',
              category: 'Renda fixa',
              benchmark: '',
              liquidity: '',
              investedCents: 10000,
              currentCents: 0,
              monthlyYieldCents: 0,
            ),
          ],
        ),
      ),
    );
    expect(
      find.text(
        'Os fundos cadastrados não têm valores atuais positivos para distribuir por categoria.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Cadastre fundos'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('budget chart explains overbudget amount', (tester) async {
    await tester.pumpWidget(
      app(
        SingleChildScrollView(
          child: BudgetUseChart(
            budgets: const [BudgetProgress('Moradia', 10000, 12500)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('acima do limite'), findsOneWidget);
    expect(find.textContaining('R\$ 25,00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('goal chart shows current target and empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const SingleChildScrollView(
          child: Column(
            children: [
              GoalProgressChart(savedCents: 25000, targetCents: 100000),
              GoalProgressChart(savedCents: 0, targetCents: 0),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('R\$ 250,00 de R\$ 1.000,00'), findsOneWidget);
    expect(find.textContaining('Defina um objetivo positivo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('twelve months remain present at compact large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final flows = [
      for (var i = 1; i <= 12; i++)
        MonthlyFlow(
          '2026-${i.toString().padLeft(2, '0')}',
          i * 1000,
          i * 500,
          0,
        ),
    ];
    await tester.pumpWidget(
      app(SingleChildScrollView(child: MonthlyChart(flows: flows))),
    );
    await tester.pumpAndSettle();
    for (var i = 1; i <= 12; i++) {
      expect(find.text(i.toString().padLeft(2, '0')), findsWidgets);
    }
    expect(tester.takeException(), isNull);
  });
}
