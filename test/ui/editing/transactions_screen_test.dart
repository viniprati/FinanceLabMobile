import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financelab_mobile/domain/models.dart';
import 'package:financelab_mobile/ui/screens/transactions_screen.dart';

void main() {
  testWidgets('valida categoria e preserva formulário', (tester) async {
    FinanceData? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionsScreen(
            data: const FinanceData(),
            onDataChanged: (v) => changed = v,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Adicionar'));
    await tester.pump();
    expect(find.text('Informe a categoria'), findsOneWidget);
    expect(changed, isNull);
  });

  testWidgets('adiciona aporte com centavos e subcategoria', (tester) async {
    FinanceData? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionsScreen(
            data: const FinanceData(),
            onDataChanged: (v) => changed = v,
          ),
        ),
      ),
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Investimentos');
    await tester.enterText(fields.at(1), 'Reserva');
    await tester.enterText(fields.at(3), '12,34');
    await tester.tap(find.text('Adicionar'));
    await tester.pump();
    expect(changed?.transactions.single.amountCents, 1234);
    expect(changed?.transactions.single.subcategory, 'Reserva');
  });
}
