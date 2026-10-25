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

  Widget _brandHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: scheme.onPrimaryContainer,
              size: 30,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'FinanceLab',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                'Seu dinheiro, com clareza.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _demoCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: widget.loading ? null : widget.onDemo,
              child: const Text(
                'Explorar demonstração',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Sem cadastro e sem internet. Dados fictícios ficam só nesta sessão.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorMessage(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Semantics(
        liveRegion: true,
        child: Text(
          widget.error!,
          style: TextStyle(color: scheme.onErrorContainer),
        ),
      ),
    );
  }

  Widget _loginForm() => Form(
    key: formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: email,
          focusNode: emailFocus,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
          textInputAction: TextInputAction.next,
          autocorrect: false,
          onFieldSubmitted: (_) => passwordFocus.requestFocus(),
          decoration: const InputDecoration(labelText: 'E-mail'),
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
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: widget.loading ? null : submit,
          child: widget.loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  widget.baseUri == null ? 'Entrar na demonstração' : 'Entrar',
                  textAlign: TextAlign.center,
                ),
        ),
      ],
    ),
  );

  Widget _loginCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Acesse sua conta',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Acompanhe receitas, gastos, fundos e metas.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            _loginForm(),
          ],
        ),
      ),
    );
  }

  Widget _offlineCredentials(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerLow,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        title: const Text('Entrar com credenciais da demo'),
        children: [
          Text(
            'E-mail: ${DemoAccess.email}\nSenha: ${DemoAccess.password}',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          _loginForm(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offlineDemo = widget.baseUri == null && widget.onDemo != null;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final horizontal = viewport.maxWidth < 400
                ? AppSpacing.md
                : AppSpacing.lg;
            final vertical = viewport.maxHeight < 600
                ? AppSpacing.md
                : AppSpacing.lg;
            final minimumHeight = viewport.maxHeight > vertical * 2
                ? viewport.maxHeight - vertical * 2
                : 0.0;
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(
                horizontal: horizontal,
                vertical: vertical,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minimumHeight),
                child: Align(
                  alignment: const Alignment(0, -0.5),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _brandHeader(context),
                        const SizedBox(height: AppSpacing.lg),
                        if (widget.error != null) ...[
                          _errorMessage(context),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        if (offlineDemo) ...[
                          _demoCard(context),
                          const SizedBox(height: AppSpacing.sm),
                          _offlineCredentials(context),
                        ] else ...[
                          _loginCard(context),
                          if (widget.onDemo != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            _demoCard(context),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
