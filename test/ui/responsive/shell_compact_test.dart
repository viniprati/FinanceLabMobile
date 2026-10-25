import 'package:financelab_mobile/app_controller.dart';
import 'package:financelab_mobile/home_shell.dart';
import 'package:financelab_mobile/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'demo banner stays concise while exposing its full status to screen readers',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = AppController(null)..enterDemo();
      addTearDown(controller.dispose);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: HomeShell(
              controller: controller,
              apiUri: null,
              openLegal: (_) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Demonstração local • dados fictícios'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'Demonstração local')),
        findsOneWidget,
      );
      expect(find.text('Início'), findsWidgets);
      expect(find.text('Lançamentos'), findsOneWidget);
      expect(find.text('Análise'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('shell keeps the month selector available on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AppController(null)..enterDemo();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: HomeShell(
          controller: controller,
          apiUri: null,
          openLegal: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Selecionar mês'), findsOneWidget);
    expect(find.byTooltip('Atualizar dados'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
