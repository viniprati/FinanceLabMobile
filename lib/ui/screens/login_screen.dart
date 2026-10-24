import 'package:flutter/material.dart';

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
  bool accepted = false;
  bool obscure = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
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
    if (widget.baseUri == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Suas finanças, com clareza.',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'A API ainda não foi configurada neste APK. '
                      'Explore a interface com dados fictícios.',
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: widget.onDemo,
                      child: const Text('Explorar demonstração'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
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
          const SizedBox(height: 24),
          Text(
            'Suas finanças, com clareza.',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Acompanhe gastos, receitas, fundos e metas em um só lugar.',
          ),
          const SizedBox(height: 28),
          if (widget.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(widget.error!),
            ),
          TextFormField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              helperText: 'Digite o e-mail da sua conta.',
            ),
            validator: (v) => v == null || !v.contains('@')
                ? 'Informe um e-mail válido.'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: password,
            obscureText: obscure,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
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
          const SizedBox(height: 14),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: accepted,
            onChanged: widget.loading
                ? null
                : (v) => setState(() => accepted = v ?? false),
            title: Wrap(
              children: [
                const Text('Aceito os '),
                _Link(label: 'Termos de Uso', onTap: widget.onTerms),
                const Text(' e a '),
                _Link(
                  label: 'Política de Privacidade',
                  onTap: widget.onPrivacy,
                ),
                const Text('.'),
              ],
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: widget.loading ? null : submit,
            child: widget.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Entrar'),
          ),
          if (widget.onDemo != null) ...[
            const SizedBox(height: 10),
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
            padding: const EdgeInsets.all(24),
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

class _Link extends StatelessWidget {
  const _Link({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Text(
      label,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w700,
        decoration: TextDecoration.underline,
      ),
    ),
  );
}
