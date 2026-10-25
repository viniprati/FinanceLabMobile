import 'package:financelab_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financelab_mobile/domain/demo_access.dart';

void main() {
  testWidgets('credenciais demo entram sem API e sem aceite de termos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Explorar demonstração'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), DemoAccess.email);
    await tester.enterText(
      find.byType(TextFormField).at(1),
      DemoAccess.password,
    );
    await tester.ensureVisible(find.text('Entrar na demonstração'));
    await tester.tap(find.text('Entrar na demonstração'));
    await tester.pumpAndSettle();

    expect(find.text('Demonstração local • dados fictícios'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
    expect(find.text('Demonstração local • dados fictícios'), findsOneWidget);
    expect(find.text('Saldo do mês'), findsOneWidget);

    await tester.tap(find.text('Lançamentos').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Novo lançamento'), findsOneWidget);
    expect(find.text('Buscar'), findsOneWidget);

    await tester.tap(find.text('Mais').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Fundos'));
    await tester.pumpAndSettle();
    expect(find.text('Novo fundo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
