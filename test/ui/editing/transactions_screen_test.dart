import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financelab_mobile/domain/models.dart';
import 'package:financelab_mobile/ui/screens/transactions_screen.dart';

void main() {
  testWidgets('lista e busca aparecem antes do formulário', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionsScreen(
            data: const FinanceData(),
            onDataChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Novo lançamento'), findsOneWidget);
    expect(find.text('Buscar'), findsOneWidget);
    expect(find.text('Adicionar'), findsNothing);
  });

  testWidgets('bloqueia edição quando o rascunho local não pode ser lido', (
    tester,
  ) async {
    final data = FinanceData(
      transactions: [
        Transaction(
          id: 't1',
          type: 'expense',
          kind: 'expense',
          date: '2026-10-24',
          category: 'Casa',
          subcategory: '',
          description: 'Aluguel',
          amountCents: 10000,
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionsScreen(
            data: data,
            editingBlocked: true,
            onDataChanged: (_) => fail('edição bloqueada'),
          ),
        ),
      ),
    );

    expect(find.text('Aluguel'), findsOneWidget);
    expect(find.text('Buscar'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton).first).onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byTooltip('Remover'),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );
  });

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
    await tester.tap(find.text('Novo lançamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    await tester.pump();
    expect(find.text('Informe a categoria'), findsOneWidget);
    expect(changed, isNull);
  });

  testWidgets('recolher o formulário preserva os campos preenchidos', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionsScreen(
            data: const FinanceData(),
            onDataChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Novo lançamento'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Moradia');
    await tester.enterText(fields.at(2), 'Aluguel');
    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Novo lançamento'));
    await tester.pumpAndSettle();

    expect(find.text('Adicionar'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(fields.at(0)).controller?.text,
      'Moradia',
    );
    expect(
      tester.widget<TextFormField>(fields.at(2)).controller?.text,
      'Aluguel',
    );
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
    await tester.tap(find.text('Novo lançamento'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Investimentos');
    await tester.enterText(fields.at(1), 'Reserva');
    await tester.enterText(fields.at(3), '12,34');
    await tester.tap(find.text('Adicionar'));
    await tester.pump();
    expect(changed?.transactions.single.amountCents, 1234);
    expect(changed?.transactions.single.subcategory, 'Reserva');
    expect(find.text('Novo lançamento'), findsOneWidget);
    expect(find.text('Adicionar'), findsNothing);
  });
}
