import 'package:financelab_mobile/ui/screens/login_screen.dart';
import 'package:financelab_mobile/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({
  required Uri? baseUri,
  required VoidCallback onDemo,
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) {
  final theme = brightness == Brightness.dark
      ? AppTheme.dark()
      : AppTheme.light();
  return MaterialApp(
    theme: theme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: LoginScreen(
      baseUri: baseUri,
      onLogin: (_, _, _) async {},
      onDemo: onDemo,
      onTerms: () {},
      onPrivacy: () {},
    ),
  );
}

void _setCompactLargeText(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  addTearDown(tester.view.resetViewPadding);
}

void main() {
  testWidgets(
    'login offline prioritizes one demo action on a compact large-text screen',
    (tester) async {
      _setCompactLargeText(tester);
      await tester.pumpWidget(_app(baseUri: null, onDemo: () {}, textScale: 2));
      await tester.pumpAndSettle();

      expect(find.text('Explorar demonstração'), findsOneWidget);
      expect(find.text('Explorar demonstração').hitTestable(), findsOneWidget);
      expect(
        tester
            .getRect(
              find.ancestor(
                of: find.text('Explorar demonstração'),
                matching: find.byType(FilledButton),
              ),
            )
            .bottom,
        lessThanOrEqualTo(616),
      );
      expect(find.text('Entrar na demonstração'), findsNothing);
      expect(find.text('Entrar com credenciais da demo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'offline credential form opens and keeps submit reachable above the keyboard',
    (tester) async {
      _setCompactLargeText(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpWidget(_app(baseUri: null, onDemo: () {}, textScale: 2));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Entrar com credenciais da demo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entrar com credenciais da demo'));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Entrar na demonstração'), findsOneWidget);
      await tester.ensureVisible(find.text('Entrar na demonstração'));
      expect(find.text('Entrar na demonstração').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('online login keeps remote fields and demo action available', (
    tester,
  ) async {
    _setCompactLargeText(tester);
    await tester.pumpWidget(
      _app(
        baseUri: Uri.parse('https://example.test'),
        onDemo: () {},
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Explorar demonstração'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('login has no layout exception in ${brightness.name} theme', (
      tester,
    ) async {
      _setCompactLargeText(tester);
      await tester.pumpWidget(
        _app(
          baseUri: Uri.parse('https://example.test'),
          onDemo: () {},
          brightness: brightness,
          textScale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
