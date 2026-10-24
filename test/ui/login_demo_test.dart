import 'package:financelab_mobile/domain/demo_access.dart';
import 'package:financelab_mobile/ui/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'APK com API mantém botão e aceita demo sem termos nem login remoto',
    (tester) async {
      var demoCalls = 0;
      var apiCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            baseUri: Uri.parse('https://example.test'),
            onLogin: (_, _, _) async {
              apiCalls++;
            },
            onDemo: () => demoCalls++,
          ),
        ),
      );

      expect(find.text('Explorar demonstração'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        DemoAccess.email,
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        DemoAccess.password,
      );
      await tester.ensureVisible(find.text('Entrar'));
      await tester.tap(find.text('Entrar'));
      await tester.pump();
      expect(demoCalls, 1);
      expect(apiCalls, 0);

      await tester.ensureVisible(find.text('Explorar demonstração'));
      await tester.tap(find.text('Explorar demonstração'));
      await tester.pump();
      expect(demoCalls, 2);
      expect(apiCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
