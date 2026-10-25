import 'package:financelab_mobile/app_controller.dart';
import 'package:financelab_mobile/home_shell.dart';
import 'package:financelab_mobile/main.dart';
import 'package:financelab_mobile/ui/screens/data_privacy_screen.dart';
import 'package:financelab_mobile/ui/screens/login_screen.dart';
import 'package:financelab_mobile/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login keeps actions reachable with keyboard and 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: LoginScreen(
          baseUri: Uri.parse('https://example.test'),
          onLogin: (_, _, _) async {},
          onDemo: () {},
          onTerms: () {},
          onPrivacy: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Explorar demonstração'));
    await tester.pumpAndSettle();
    expect(find.text('Explorar demonstração').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);

    final terms = find.ancestor(
      of: find.text('Termos de Uso'),
      matching: find.byType(TextButton),
    );
    final privacy = find.ancestor(
      of: find.text('Política de Privacidade'),
      matching: find.byType(TextButton),
    );
    expect(terms, findsOneWidget);
    expect(privacy, findsOneWidget);
    expect(tester.getSize(terms).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(privacy).height, greaterThanOrEqualTo(48));
  });

  testWidgets('empty login focuses the first invalid field', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: LoginScreen(
          baseUri: Uri.parse('https://example.test'),
          onLogin: (_, _, _) async {},
        ),
      ),
    );

    await tester.ensureVisible(find.text('Entrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .focusNode
          .hasFocus,
      isTrue,
    );
  });

  testWidgets('demo navigation stays usable at 320 dp and 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Explorar demonstração'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explorar demonstração'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final transactionsTab = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Lançamentos'),
    );
    expect(transactionsTab, findsOneWidget);
    await tester.tap(transactionsTab);
    await tester.pumpAndSettle();
    expect(find.text('Novo lançamento'), findsOneWidget);
    expect(find.text('Buscar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet keeps rail navigation and editing reachable at 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Explorar demonstração'));
    await tester.tap(find.text('Explorar demonstração'));
    await tester.pumpAndSettle();

    final rail = find.byType(NavigationRail);
    expect(rail, findsOneWidget);
    final fundsIcon = find.descendant(
      of: rail,
      matching: find.byIcon(Icons.account_balance_outlined),
    );
    await tester.tap(fundsIcon);
    await tester.pumpAndSettle();
    expect(find.text('Novo fundo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long save status remains readable with the keyboard open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final controller = AppController(null)..enterDemo();
    addTearDown(controller.dispose);
    controller.demo = false;
    controller.saveError =
        'Não foi possível confirmar a gravação. Preserve uma cópia local '
        'antes de tentar novamente.';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: HomeShell(
          controller: controller,
          apiUri: null,
          openLegal: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Tentar novamente').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('data privacy actions remain reachable at 320 dp and 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AppController(null)..enterDemo();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: DataPrivacyScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Importar dados financeiros'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Importar dados financeiros').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('both themes keep labels and accessible semantic color pairs', () {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      expect(
        theme.inputDecorationTheme.floatingLabelBehavior,
        FloatingLabelBehavior.always,
      );
      expect(theme.inputDecorationTheme.filled, isTrue);
      final scheme = theme.colorScheme;
      expect(
        _contrast(scheme.onSurface, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(scheme.onPrimary, scheme.primary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(scheme.onSecondaryContainer, scheme.secondaryContainer),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(scheme.onErrorContainer, scheme.errorContainer),
        greaterThanOrEqualTo(4.5),
      );
    }
  });
}

double _contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  final brighter = a > b ? a : b;
  final darker = a > b ? b : a;
  return (brighter + 0.05) / (darker + 0.05);
}
