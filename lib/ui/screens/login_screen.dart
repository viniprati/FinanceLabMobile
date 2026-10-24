import 'package:flutter/material.dart';

import '../../domain/demo_access.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLogin,
    this.onDemo,
    this.onTerms,
    this.onPrivacy,
    this.baseUri,
    this.loading = false,
    this.error,
  });
  final Future<void> Function(String email, String password, bool acceptedLegal)
  onLogin;
  final VoidCallback? onDemo;
  final VoidCallback? onTerms;
  final VoidCallback? onPrivacy;
  final Uri? baseUri;
  final bool loading;
  final String? error;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();
  bool accepted = false;
  bool obscure = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (widget.loading) return;
    if (!(formKey.currentState?.validate() ?? false)) {
      final target = email.text.contains('@') ? passwordFocus : emailFocus;
      target.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || target.context == null) return;
        Scrollable.ensureVisible(
          target.context!,
          duration: const Duration(milliseconds: 200),
          alignment: 0.2,
        );
      });
      return;
    }
    if (DemoAccess.matches(email.text, password.text) &&
        widget.onDemo != null) {
      widget.onDemo!();
      return;
    }
    if (widget.baseUri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sem API, use as credenciais da demonstração.'),
        ),
      );
      return;
    }
    if (!accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aceite os termos para continuar.')),
      );
      return;
    }
    await widget.onLogin(email.text.trim(), password.text, accepted);
  }

  @override
  Widget build(BuildContext context) {
    final form = Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Suas finanças, com clareza.',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.baseUri == null
                ? 'A API ainda não foi configurada neste APK. '
                      'Entre na demonstração local ou use o botão abaixo.'
                : 'Acompanhe gastos, receitas, fundos e metas em um só lugar.',
          ),
          const SizedBox(height: AppSpacing.md),
          if (widget.onDemo != null)
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Demonstração sem internet',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: AppSpacing.xxs),
                    Text(
                      'E-mail: ${DemoAccess.email}\n'
                      'Senha: ${DemoAccess.password}',
                    ),
                    SizedBox(height: AppSpacing.xxs),
                    Text('Dados fictícios salvos somente nesta sessão.'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          if (widget.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  widget.error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          TextFormField(
            controller: email,
            focusNode: emailFocus,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            textInputAction: TextInputAction.next,
            autocorrect: false,
            onFieldSubmitted: (_) => passwordFocus.requestFocus(),
            decoration: InputDecoration(
              labelText: 'E-mail',
              helperText: widget.baseUri == null
                  ? 'Use o e-mail da demonstração acima.'
                  : 'Digite o e-mail da sua conta.',
            ),
            validator: (v) => v == null || !v.contains('@')
                ? 'Informe um e-mail válido.'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: password,
            focusNode: passwordFocus,
            obscureText: obscure,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            autocorrect: false,
            onFieldSubmitted: (_) => submit(),
            decoration: InputDecoration(
              labelText: 'Senha',
              suffixIcon: IconButton(
                tooltip: obscure ? 'Mostrar senha' : 'Ocultar senha',
                onPressed: () => setState(() => obscure = !obscure),
                icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
              ),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Informe sua senha.' : null,
          ),
          if (widget.baseUri != null) ...[
            const SizedBox(height: AppSpacing.sm),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: accepted,
              onChanged: widget.loading
                  ? null
                  : (v) => setState(() => accepted = v ?? false),
              title: const Text(
                'Aceito os Termos de Uso e a Política de Privacidade.',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              children: [
                TextButton(
                  onPressed: widget.onTerms,
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  child: const Text('Termos de Uso'),
                ),
                TextButton(
                  onPressed: widget.onPrivacy,
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  child: const Text('Política de Privacidade'),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: widget.loading ? null : submit,
            child: widget.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    widget.baseUri == null
                        ? 'Entrar na demonstração'
                        : 'Entrar',
                  ),
          ),
          if (widget.onDemo != null) ...[
            const SizedBox(height: AppSpacing.xs),
            OutlinedButton(
              onPressed: widget.loading ? null : widget.onDemo,
              child: const Text('Explorar demonstração'),
            ),
          ],
        ],
      ),
    );
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: form,
            ),
          ),
        ),
      ),
    );
  }
}
