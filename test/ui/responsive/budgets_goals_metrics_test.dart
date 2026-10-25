import 'package:financelab_mobile/domain/models.dart';
import 'package:financelab_mobile/domain/summary.dart';
import 'package:financelab_mobile/ui/screens/budgets_screen.dart';
import 'package:financelab_mobile/ui/screens/goals_screen.dart';
import 'package:financelab_mobile/ui/screens/metrics_screen.dart';
import 'package:financelab_mobile/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final data = FinanceData(
    budgets: [
      const Budget(
        id: 'b1',
        category: 'Alimentação e compras essenciais da família',
        monthlyLimitCents: 120000,
      ),
    ],
    funds: [
      const Fund(
        id: 'f1',
        name: 'Reserva de emergência',
        account: 'Conta principal',
        category: 'Renda fixa',
        benchmark: 'CDI',
        liquidity: 'Diária',
        investedCents: 200000,
        currentCents: 210000,
        monthlyYieldCents: 1000,
      ),
    ],
  );

  Widget app(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    builder: (context, appChild) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: const TextScaler.linear(2)),
      child: appChild!,
    ),
    home: child,
  );

  void compact(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('budgets keeps category actions and save reachable at 200%', (
    tester,
  ) async {
    compact(tester);
    await tester.pumpWidget(
      app(
        BudgetsScreen(
          data: data,
          summary: FinanceSummary.fromData(data, '2026-10'),
          onDataChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Alimentação e compras essenciais da família'),
      findsOneWidget,
    );
    expect(find.byTooltip('Editar'), findsOneWidget);
    expect(find.byTooltip('Remover'), findsOneWidget);
    expect(find.text('Adicionar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'goals keeps all fields and save action scrollable on compact text',
    (tester) async {
      compact(tester);
      await tester.pumpWidget(
        app(GoalsScreen(data: data, onDataChanged: (_) {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('Orçamento mensal (R\$)'), findsOneWidget);
      expect(find.text('Meta da reserva (R\$)'), findsOneWidget);
      expect(find.text('Valor guardado (R\$)'), findsOneWidget);
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Salvar metas'),
      );
      expect(find.text('Salvar metas'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('metrics stacks portfolio cards in narrow space', (tester) async {
    compact(tester);
    await tester.pumpWidget(
      app(
        MetricsScreen(
          data: data,
          summary: FinanceSummary.fromData(data, '2026-10'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -1800));
    await tester.pumpAndSettle();
    expect(find.text('Saúde das movimentações'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
