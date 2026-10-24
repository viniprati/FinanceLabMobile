import 'package:financelab_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('abre demonstração e navega pelas seções no celular', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();
    expect(find.text('Explorar demonstração'), findsOneWidget);

    await tester.tap(find.text('Explorar demonstração'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.text('Demonstração: dados fictícios, salvos só nesta sessão.'),
      findsOneWidget,
    );
    expect(find.text('Saldo do mês'), findsOneWidget);

    await tester.tap(find.text('Lançamentos').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Adicionar'), findsOneWidget);

    await tester.tap(find.text('Mais').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Fundos'));
    await tester.pumpAndSettle();
    expect(find.text('Novo fundo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
