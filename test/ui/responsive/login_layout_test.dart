import 'package:financelab_mobile/ui/screens/login_screen.dart';
import 'package:financelab_mobile/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({
  required Uri? baseUri,
  required VoidCallback onDemo,
  Brightness brightness = Brightness.light,
}) {
  final theme = brightness == Brightness.dark
      ? AppTheme.dark()
      : AppTheme.light();
  return MaterialApp(
    theme: theme,
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
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
}

void main() {
  testWidgets(
    'login offline prioritizes one demo action on a compact large-text screen',
    (tester) async {
      _setCompactLargeText(tester);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: _app(baseUri: null, onDemo: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Explorar demonstração'), findsOneWidget);
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
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            viewInsets: EdgeInsets.only(bottom: 280),
            textScaler: TextScaler.linear(2),
          ),
          child: _app(baseUri: null, onDemo: () {}),
        ),
      );
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
      _app(baseUri: Uri.parse('https://example.test'), onDemo: () {}),
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
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: _app(
            baseUri: Uri.parse('https://example.test'),
            onDemo: () {},
            brightness: brightness,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
