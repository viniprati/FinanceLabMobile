import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financelab_mobile/domain/models.dart';
import 'package:financelab_mobile/ui/screens/goals_screen.dart';

void main() {
  testWidgets('salva metas em centavos', (tester) async {
    FinanceData? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: GoalsScreen(
          data: const FinanceData(),
          onDataChanged: (v) => changed = v,
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).first, '100,50');
    await tester.tap(find.text('Salvar metas'));
    expect(changed?.goals.monthlyBudgetCents, 10050);
  });
}
