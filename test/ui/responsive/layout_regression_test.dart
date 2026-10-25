import 'package:financelab_mobile/app_controller.dart';
import 'package:financelab_mobile/domain/models.dart';
import 'package:financelab_mobile/domain/money.dart';
import 'package:financelab_mobile/domain/summary.dart';
import 'package:financelab_mobile/home_shell.dart';
import 'package:financelab_mobile/ui/screens/analysis_screen.dart';
import 'package:financelab_mobile/ui/screens/budgets_screen.dart';
import 'package:financelab_mobile/ui/screens/data_privacy_screen.dart';
import 'package:financelab_mobile/ui/screens/funds_screen.dart';
import 'package:financelab_mobile/ui/screens/goals_screen.dart';
import 'package:financelab_mobile/ui/screens/login_screen.dart';
import 'package:financelab_mobile/ui/screens/metrics_screen.dart';
import 'package:financelab_mobile/ui/screens/overview_screen.dart';
import 'package:financelab_mobile/ui/screens/transactions_screen.dart';
import 'package:financelab_mobile/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _longCategory = 'Alimentação, compras essenciais e despesas da família';
const _largeCents = 123456789012;
const _data = FinanceData(
  transactions: [
    Transaction(
      id: 'expense',
      type: 'expense',
      kind: 'expense',
      date: '2026-10-24',
      category: _longCategory,
      subcategory: 'Compras de supermercado para a família',
      description: 'Compra mensal de itens essenciais e outras despesas',
      amountCents: _largeCents,
    ),
    Transaction(
      id: 'income',
      type: 'income',
      kind: 'income',
      date: '2026-10-24',
      category: 'Salário',
      subcategory: '',
      description: 'Salário',
      amountCents: 100,
    ),
  ],
  budgets: [
    Budget(id: 'budget', category: _longCategory, monthlyLimitCents: 100),
  ],
  funds: [
    Fund(
      id: 'fund',
      name: 'Fundo de investimento com nome bastante comprido',
      account: 'Corretora principal',
      category: 'Renda fixa',
      benchmark: 'CDI',
      liquidity: 'Diária',
      investedCents: _largeCents,
      currentCents: 100,
      monthlyYieldCents: -100,
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required Size size,
  required double scale,
  required Brightness brightness,
  double keyboard = 0,
  bool wrapScaffold = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewPadding);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: wrapScaffold ? Scaffold(body: child) : child,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final summary = FinanceSummary.fromData(
    _data,
    '2026-10',
    now: DateTime(2026, 10, 25),
  );
  const sizes = [
    Size(320, 640),
    Size(360, 800),
    Size(412, 915),
    Size(800, 1280),
    Size(640, 320),
  ];

  for (final size in sizes) {
    for (final scale in [1.0, 1.3, 2.0]) {
      for (final brightness in Brightness.values) {
        testWidgets(
          'transactions and overview at ${size.width}x${size.height}, '
          '${scale}x, ${brightness.name}',
          (tester) async {
            await _pump(
              tester,
              TransactionsScreen(data: _data, onDataChanged: (_) {}),
              size: size,
              scale: scale,
              brightness: brightness,
            );
            await tester.tap(find.text('Novo lançamento'));
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.text('Adicionar'));
            await tester.pumpAndSettle();
            expect(find.text('Adicionar').hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);

            await _pump(
              tester,
              OverviewScreen(data: _data, summary: summary),
              size: size,
              scale: scale,
              brightness: brightness,
            );
            await tester.scrollUntilVisible(
              find.text('Patrimônio'),
              250,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.pumpAndSettle();
            final semantics = tester.ensureSemantics();
            expect(
              find.bySemanticsLabel(
                RegExp(RegExp.escape(Money.formatBr(summary.netWorthCents))),
              ),
              findsOneWidget,
            );
            semantics.dispose();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('transaction fields retain a visible gap after validation', (
    tester,
  ) async {
    await _pump(
      tester,
      TransactionsScreen(data: _data, onDataChanged: (_) {}),
      size: const Size(360, 800),
      scale: 1,
      brightness: Brightness.light,
    );
    await tester.tap(find.text('Novo lançamento'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Adicionar'));
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe a categoria'), findsOneWidget);
    expect(find.text('Informe um valor válido'), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(TextFormField, 'Categoria'));
    await tester.pumpAndSettle();
    final category = tester.getRect(
      find.widgetWithText(TextFormField, 'Categoria'),
    );
    final subcategory = tester.getRect(
      find.widgetWithText(TextFormField, 'Subcategoria'),
    );
    expect(subcategory.top - category.bottom, greaterThanOrEqualTo(12));
    expect(tester.takeException(), isNull);
  });

  for (final screen in ['transactions', 'budgets', 'funds', 'goals', 'login']) {
    testWidgets(
      '$screen keeps validation and submit reachable above keyboard',
      (tester) async {
        final Widget child = switch (screen) {
          'transactions' => TransactionsScreen(
            data: const FinanceData(),
            onDataChanged: (_) {},
          ),
          'budgets' => BudgetsScreen(
            data: const FinanceData(),
            onDataChanged: (_) {},
          ),
          'funds' => FundsScreen(
            data: const FinanceData(),
            onDataChanged: (_) {},
          ),
          'goals' => GoalsScreen(
            data: const FinanceData(),
            onDataChanged: (_) {},
          ),
          _ => LoginScreen(
            baseUri: Uri.parse('https://example.test'),
            onLogin: (_, _, _) async {},
          ),
        };
        await _pump(
          tester,
          child,
          size: const Size(320, 640),
          scale: 2,
          brightness: Brightness.dark,
          keyboard: 280,
          wrapScaffold: screen != 'login',
        );
        if (screen == 'transactions') {
          await tester.tap(find.text('Novo lançamento'));
          await tester.pumpAndSettle();
        } else if (screen == 'goals') {
          final semantics = tester.ensureSemantics();
          expect(
            find.bySemanticsLabel('Orçamento mensal em reais'),
            findsOneWidget,
          );
          semantics.dispose();
          await tester.enterText(find.byType(TextFormField).first, '');
        }
        final action = switch (screen) {
          'goals' => find.text('Salvar metas'),
          'login' => find.text('Entrar'),
          _ => find.text('Adicionar'),
        };
        final button = find.ancestor(
          of: action,
          matching: find.byType(FilledButton),
        );
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        final scrollable = find.byType(Scrollable).first;
        for (
          var i = 0;
          i < 10 &&
              tester.getRect(button).bottom > tester.getRect(scrollable).bottom;
          i++
        ) {
          await tester.drag(scrollable, const Offset(0, -140));
          await tester.pumpAndSettle();
        }
        expect(button.hitTestable(), findsOneWidget);
        expect(
          tester.getRect(button).bottom,
          lessThanOrEqualTo(tester.getRect(scrollable).bottom),
        );
        await tester.tap(action);
        await tester.pumpAndSettle();
        final (firstLabel, firstError) = switch (screen) {
          'transactions' => ('Categoria', 'Informe a categoria'),
          'budgets' => ('Categoria', 'Informe a categoria'),
          'funds' => ('Nome', 'Informe Nome'),
          'goals' => ('Orçamento mensal (R\$)', 'Informe um valor válido'),
          _ => ('E-mail', 'Informe um e-mail válido.'),
        };
        expect(find.text(firstError), findsOneWidget);
        final firstField = screen == 'goals'
            ? find.byType(TextFormField).first
            : find.widgetWithText(TextFormField, firstLabel);
        expect(
          tester
              .widget<EditableText>(
                find.descendant(
                  of: firstField,
                  matching: find.byType(EditableText),
                ),
              )
              .focusNode
              .hasFocus,
          isTrue,
        );
        final firstRect = tester.getRect(firstField);
        expect(firstRect.top, greaterThanOrEqualTo(0));
        expect(firstRect.bottom, lessThanOrEqualTo(360));
        expect(tester.takeException(), isNull);
        expect(find.byType(TextFormField), findsWidgets);
      },
    );
  }

  testWidgets('keyboard does not leave an extra empty tail after the form', (
    tester,
  ) async {
    await _pump(
      tester,
      LoginScreen(
        baseUri: Uri.parse('https://example.test'),
        onLogin: (_, _, _) async {},
      ),
      size: const Size(320, 640),
      scale: 1.3,
      brightness: Brightness.light,
      keyboard: 280,
      wrapScaffold: false,
    );
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -3000),
    );
    await tester.pumpAndSettle();
    final lastAction = tester.getRect(find.text('Entrar'));
    expect(360 - lastAction.bottom, lessThan(80));
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 640), const Size(640, 320)]) {
    testWidgets(
      'shell keeps navigation and form action at ${size.width}x${size.height}',
      (tester) async {
        final controller = AppController(null)..enterDemo();
        addTearDown(controller.dispose);
        await _pump(
          tester,
          HomeShell(
            controller: controller,
            apiUri: null,
            openLegal: (_) async {},
          ),
          size: size,
          scale: 2,
          brightness: Brightness.dark,
          keyboard: size.height > 400 ? 280 : 0,
          wrapScaffold: false,
        );
        final nav = find.byType(NavigationBar);
        expect(nav, findsOneWidget);
        await tester.tap(
          find.descendant(of: nav, matching: find.text('Lançamentos')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Novo lançamento'), findsOneWidget);
        await tester.tap(find.text('Novo lançamento'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Adicionar'));
        await tester.pumpAndSettle();
        expect(find.text('Adicionar').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('fund fields use two columns only when each field has room', (
    tester,
  ) async {
    await _pump(
      tester,
      FundsScreen(data: const FinanceData(), onDataChanged: (_) {}),
      size: const Size(800, 1280),
      scale: 1,
      brightness: Brightness.light,
    );
    final name = find.widgetWithText(TextFormField, 'Nome');
    final account = find.widgetWithText(TextFormField, 'Conta ou corretora');
    expect(tester.getRect(name).top, tester.getRect(account).top);
    expect(
      tester.getRect(account).left,
      greaterThan(tester.getRect(name).right),
    );

    await _pump(
      tester,
      FundsScreen(data: const FinanceData(), onDataChanged: (_) {}),
      size: const Size(320, 640),
      scale: 2,
      brightness: Brightness.light,
    );
    expect(
      tester.getRect(account).top - tester.getRect(name).bottom,
      greaterThanOrEqualTo(12),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('long category menu and large amount remain readable', (
    tester,
  ) async {
    await _pump(
      tester,
      TransactionsScreen(data: _data, onDataChanged: (_) {}),
      size: const Size(320, 640),
      scale: 2,
      brightness: Brightness.dark,
    );
    final categoryFilter = find.byTooltip('Filtrar por categoria');
    await tester.ensureVisible(categoryFilter);
    await tester.pumpAndSettle();
    await tester.tap(categoryFilter);
    await tester.pumpAndSettle();
    expect(find.text(_longCategory), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large entered value keeps exact cents on submission', (
    tester,
  ) async {
    FinanceData? changed;
    await _pump(
      tester,
      TransactionsScreen(
        data: const FinanceData(),
        onDataChanged: (data) => changed = data,
      ),
      size: const Size(360, 800),
      scale: 1.3,
      brightness: Brightness.light,
    );
    await tester.tap(find.text('Novo lançamento'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Categoria'),
      _longCategory,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Valor (R\$)'),
      '1.234.567.890,12',
    );
    await tester.ensureVisible(find.text('Adicionar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    expect(changed?.transactions.single.amountCents, _largeCents);
    expect(changed?.transactions.single.category, _longCategory);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fund form keeps negative monthly yield and large cents', (
    tester,
  ) async {
    FinanceData? changed;
    await _pump(
      tester,
      FundsScreen(
        data: const FinanceData(),
        onDataChanged: (data) => changed = data,
      ),
      size: const Size(360, 800),
      scale: 1.3,
      brightness: Brightness.light,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome'),
      'Reserva',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Valor aplicado (R\$)'),
      '1.234.567.890,12',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Valor atual (R\$)'),
      '1,00',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Rendimento (R\$)'),
      '-25,40',
    );
    await tester.ensureVisible(find.text('Adicionar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    expect(changed?.funds.single.investedCents, _largeCents);
    expect(changed?.funds.single.monthlyYieldCents, -2540);
    expect(tester.takeException(), isNull);
  });

  testWidgets('financial cards show complete negative and large amounts', (
    tester,
  ) async {
    await _pump(
      tester,
      FundsScreen(data: _data, onDataChanged: (_) {}),
      size: const Size(320, 640),
      scale: 2,
      brightness: Brightness.dark,
    );
    await tester.scrollUntilVisible(
      find.text('Valor atual'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    final fundSemantics = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(
        RegExp(RegExp.escape(Money.formatBr(100 - _largeCents))),
      ),
      findsOneWidget,
    );
    fundSemantics.dispose();
    expect(tester.takeException(), isNull);

    await _pump(
      tester,
      MetricsScreen(data: _data, summary: summary),
      size: const Size(320, 640),
      scale: 2,
      brightness: Brightness.dark,
    );
    final semantics = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(
        RegExp(RegExp.escape(Money.formatBr(summary.cashBalanceCents))),
      ),
      findsOneWidget,
    );
    semantics.dispose();
    expect(tester.takeException(), isNull);

    await _pump(
      tester,
      AnalysisScreen(data: _data, summary: summary),
      size: const Size(320, 640),
      scale: 2,
      brightness: Brightness.dark,
    );
    await tester.scrollUntilVisible(
      find.text('Histórico mensal'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('privacy page respects the lower system safe area', (
    tester,
  ) async {
    final controller = AppController(null)..enterDemo();
    addTearDown(controller.dispose);
    await _pump(
      tester,
      DataPrivacyScreen(controller: controller),
      size: const Size(320, 640),
      scale: 2,
      brightness: Brightness.dark,
      wrapScaffold: false,
    );
    final finalMessage = find.text(
      'Exportação e solicitação LGPD exigem uma conta conectada.',
    );
    await tester.scrollUntilVisible(
      finalMessage,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(finalMessage.hitTestable(), findsOneWidget);
    expect(tester.getRect(finalMessage).bottom, lessThanOrEqualTo(616));
    expect(tester.takeException(), isNull);
  });
}
