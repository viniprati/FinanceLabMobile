import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_controller.dart';
import 'data/api.dart';
import 'home_shell.dart';
import 'ui/screens/login_screen.dart';
import 'ui/theme/app_theme.dart';

const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final Uri? apiUri = _configuredApiUri(_apiBaseUrl);
  late final AppController controller = AppController(
    apiUri == null ? null : FinanceApi(apiUri!),
  );

  @override
  void initState() {
    super.initState();
    unawaited(controller.initialize());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> openLegal(String path) async {
    final base = apiUri;
    if (base == null) return;
    final opened = await launchUrl(
      base.resolve(path),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      messengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o documento.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FinanceLab',
    debugShowCheckedModeBanner: false,
    scaffoldMessengerKey: messengerKey,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: ThemeMode.system,
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.initializing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (controller.user == null) {
          return LoginScreen(
            onLogin: controller.login,
            onDemo: controller.enterDemo,
            onTerms: apiUri == null
                ? null
                : () => unawaited(openLegal('/termos-de-uso')),
            onPrivacy: apiUri == null
                ? null
                : () => unawaited(openLegal('/politica-de-privacidade')),
            baseUri: apiUri,
            loading: controller.busy,
            error: controller.error,
          );
        }
        return HomeShell(
          controller: controller,
          apiUri: apiUri,
          openLegal: openLegal,
        );
      },
    ),
  );
}

Uri? _configuredApiUri(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || uri.scheme != 'https' || !uri.hasAuthority) return null;
  return uri;
}
