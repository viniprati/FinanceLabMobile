import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financelab_mobile/domain/models.dart';
import 'package:financelab_mobile/ui/screens/funds_screen.dart';
import 'package:financelab_mobile/ui/screens/transactions_screen.dart';

void main() {
  const compact = Size(320, 640);

  Widget shell(Widget child) => MediaQuery(
    data: const MediaQueryData(
      size: compact,
      textScaler: TextScaler.linear(2),
      viewInsets: EdgeInsets.only(bottom: 280),
    ),
    child: MaterialApp(home: Scaffold(body: child)),
  );

  testWidgets('transactions stays usable with large text and keyboard inset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      shell(
        TransactionsScreen(
          data: FinanceData.fromJson({
            'transactions': [
              {
                'id': 'long',
                'type': 'expense',
                'kind': 'expense',
                'date': '2026-10-24',
                'category': 'Categoria com nome comprido',
                'description': 'Descrição longa para não cortar',
                'amount': 1234.56,
              },
            ],
            'funds': <Map<String, dynamic>>[],
            'budgets': <Map<String, dynamic>>[],
            'goals': {
              'monthlyBudget': 0,
              'emergencyFund': 0,
              'emergencySaved': 0,
            },
          }),
          onDataChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Novo lançamento'), findsOneWidget);
    expect(find.text('Adicionar'), findsNothing);
    await tester.tap(find.text('Novo lançamento'));
    await tester.pumpAndSettle();
    expect(find.text('Adicionar'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsWidgets);
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pump();

    expect(find.byType(TransactionsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fund actions wrap below content on compact large text', (
    tester,
  ) async {
    await tester.pumpWidget(
      shell(
        FundsScreen(
          data: FinanceData.fromJson({
            'transactions': <Map<String, dynamic>>[],
            'funds': [
              {
                'id': 'fund',
                'name': 'Fundo de investimento com nome comprido',
                'account': 'Corretora principal',
                'category': 'Renda fixa',
                'benchmark': 'CDI',
                'liquidity': 'D+1',
                'invested': 1000,
                'current': 1100,
                'monthlyYield': 10,
              },
            ],
            'budgets': <Map<String, dynamic>>[],
            'goals': {
              'monthlyBudget': 0,
              'emergencyFund': 0,
              'emergencySaved': 0,
            },
          }),
          onDataChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pump();

    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Remover'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
