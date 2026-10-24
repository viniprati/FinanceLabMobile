import 'dart:async';

import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'ui/screens/analysis_screen.dart';
import 'ui/screens/budgets_screen.dart';
import 'ui/screens/data_privacy_screen.dart';
import 'ui/screens/funds_screen.dart';
import 'ui/screens/goals_screen.dart';
import 'ui/screens/metrics_screen.dart';
import 'ui/screens/overview_screen.dart';
import 'ui/screens/transactions_screen.dart';

enum AppSection {
  overview('Início', Icons.dashboard_outlined, Icons.dashboard),
  transactions('Lançamentos', Icons.receipt_long_outlined, Icons.receipt_long),
  analysis('Análise', Icons.bar_chart_outlined, Icons.bar_chart),
  metrics('Métricas', Icons.speed_outlined, Icons.speed),
  budgets('Orçamentos', Icons.pie_chart_outline, Icons.pie_chart),
  funds('Fundos', Icons.account_balance_outlined, Icons.account_balance),
  goals('Metas', Icons.flag_outlined, Icons.flag),
  more('Mais', Icons.more_horiz, Icons.more_horiz);

  const AppSection(this.title, this.icon, this.selectedIcon);
  final String title;
  final IconData icon;
  final IconData selectedIcon;
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.controller,
    required this.apiUri,
    required this.openLegal,
  });

  final AppController controller;
  final Uri? apiUri;
  final Future<void> Function(String path) openLegal;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  AppSection section = AppSection.overview;
  AppController get controller => widget.controller;

  Future<void> _logout() async {
    final hasDraft = controller.hasUnsavedChanges || controller.unreadableDraft;
    if (hasDraft) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            controller.unreadableDraft
                ? 'Sair com rascunho local?'
                : 'Sair com alterações pendentes?',
          ),
          content: Text(
            controller.unreadableDraft
                ? 'O rascunho local não pôde ser lido. Sair agora o descartará. '
                      'Você pode salvar uma cópia antes.'
                : 'As alterações ainda não foram confirmadas pelo servidor. '
                      'Sair agora as descartará.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continuar no app'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
                unawaited(_openDataPrivacy());
              },
              child: const Text('Salvar cópia local'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sair e descartar'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await controller.logout(discardPendingDraft: hasDraft);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = controller.user?.role == 'admin';
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;
    final active = section;
    final body = isAdmin
        ? _AdminOverview(controller: controller)
        : _sectionBody(active);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isAdmin ? 'Administração' : active.title),
            if (!isAdmin && active != AppSection.more)
              Text(
                monthLabel(controller.selectedMonth),
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
        actions: [
          if (isAdmin)
            PopupMenuButton<String>(
              tooltip: 'Conta e privacidade',
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'data') {
                  unawaited(_openDataPrivacy());
                } else if (value == 'terms') {
                  unawaited(widget.openLegal('/termos-de-uso'));
                } else if (value == 'privacy') {
                  unawaited(widget.openLegal('/politica-de-privacidade'));
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'data',
                  child: Text('Meus dados e privacidade'),
                ),
                if (widget.apiUri != null) ...const [
                  PopupMenuItem(value: 'terms', child: Text('Termos de Uso')),
                  PopupMenuItem(
                    value: 'privacy',
                    child: Text('Política de Privacidade'),
                  ),
                ],
              ],
            ),
          if (!isAdmin)
            PopupMenuButton<String>(
              tooltip: 'Selecionar mês',
              icon: const Icon(Icons.calendar_month_outlined),
              onSelected: controller.selectMonth,
              itemBuilder: (context) => [
                for (final month in controller.availableMonths)
                  PopupMenuItem(value: month, child: Text(monthLabel(month))),
              ],
            ),
          IconButton(
            tooltip: 'Atualizar dados',
            onPressed: controller.busy
                ? null
                : () => unawaited(controller.refresh()),
            icon: const Icon(Icons.refresh),
          ),
          if (wide)
            IconButton(
              tooltip: 'Sair',
              onPressed: () => unawaited(_logout()),
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      drawer: wide || isAdmin ? null : _mobileDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            if (controller.demo)
              const _StatusStrip(
                icon: Icons.science_outlined,
                text: 'Demonstração: dados fictícios, salvos só nesta sessão.',
              )
            else if (controller.saveError != null)
              _StatusStrip(
                icon: Icons.error_outline,
                text:
                    controller.draftCleanupFailed || controller.unreadableDraft
                    ? controller.saveError!
                    : 'Não foi possível salvar: ${controller.saveError}',
                action: TextButton(
                  onPressed:
                      controller.conflictDetected || controller.unreadableDraft
                      ? () => unawaited(_openDataPrivacy())
                      : controller.draftCleanupFailed
                      ? () => unawaited(controller.retryDraftCleanup())
                      : () => unawaited(
                          controller.sessionExpired
                              ? controller.reloginPreservingDraft()
                              : controller.retrySave(),
                        ),
                  child: Text(
                    controller.conflictDetected || controller.unreadableDraft
                        ? 'Revisar dados'
                        : controller.draftCleanupFailed
                        ? 'Limpar cópia antiga'
                        : controller.sessionExpired
                        ? 'Entrar novamente'
                        : 'Tentar novamente',
                  ),
                ),
              )
            else if (controller.saving)
              const _StatusStrip(
                icon: Icons.sync,
                text: 'Salvando alterações…',
              ),
            if (controller.error != null)
              _StatusStrip(icon: Icons.info_outline, text: controller.error!),
            Expanded(
              child: wide && !isAdmin
                  ? Row(
                      children: [
                        NavigationRail(
                          extended: width >= 1200,
                          scrollable: true,
                          selectedIndex: AppSection.values.indexOf(active),
                          onDestinationSelected: (index) => setState(
                            () => section = AppSection.values[index],
                          ),
                          destinations: [
                            for (final value in AppSection.values)
                              NavigationRailDestination(
                                icon: Icon(value.icon),
                                selectedIcon: Icon(value.selectedIcon),
                                label: Text(value.title),
                              ),
                          ],
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: body),
                      ],
                    )
                  : body,
            ),
          ],
        ),
      ),
      bottomNavigationBar: !wide && !isAdmin
          ? NavigationBar(
              selectedIndex: _bottomIndex(active),
              onDestinationSelected: (index) => setState(() {
                section = switch (index) {
                  0 => AppSection.overview,
                  1 => AppSection.transactions,
                  2 => AppSection.analysis,
                  _ => AppSection.more,
                };
              }),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Início',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'Lançamentos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: 'Análise',
                ),
                NavigationDestination(
                  icon: Icon(Icons.more_horiz),
                  label: 'Mais',
                ),
              ],
            )
          : null,
    );
  }

  Widget _mobileDrawer() => Drawer(
    child: SafeArea(
      child: ListView(
        children: [
          ListTile(
            title: const Text('FinanceLab'),
            subtitle: Text(controller.user?.name ?? ''),
          ),
          const Divider(),
          for (final value in AppSection.values)
            ListTile(
              leading: Icon(value.icon),
              title: Text(value.title),
              selected: section == value,
              onTap: () {
                Navigator.pop(context);
                setState(() => section = value);
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () {
              Navigator.pop(context);
              unawaited(_logout());
            },
          ),
        ],
      ),
    ),
  );

  Widget _sectionBody(AppSection selected) {
    final data = controller.data;
    final summary = controller.summary;
    return switch (selected) {
      AppSection.overview => OverviewScreen(data: data, summary: summary),
      AppSection.transactions => TransactionsScreen(
        data: data,
        summary: summary,
        monthKey: controller.selectedMonth,
        onDataChanged: controller.updateData,
      ),
      AppSection.analysis => AnalysisScreen(data: data, summary: summary),
      AppSection.metrics => MetricsScreen(data: data, summary: summary),
      AppSection.budgets => BudgetsScreen(
        data: data,
        summary: summary,
        onDataChanged: controller.updateData,
      ),
      AppSection.funds => FundsScreen(
        data: data,
        summary: summary,
        onDataChanged: controller.updateData,
      ),
      AppSection.goals => GoalsScreen(
        data: data,
        summary: summary,
        onDataChanged: controller.updateData,
      ),
      AppSection.more => _MorePage(
        controller: controller,
        apiUri: widget.apiUri,
        onSelect: (value) => setState(() => section = value),
        onLogout: _logout,
        onOpenLegal: widget.openLegal,
        onDataPrivacy: _openDataPrivacy,
      ),
    };
  }

  Future<void> _openDataPrivacy() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DataPrivacyScreen(controller: controller),
    ),
  );
}

int _bottomIndex(AppSection section) => switch (section) {
  AppSection.overview => 0,
  AppSection.transactions => 1,
  AppSection.analysis => 2,
  _ => 3,
};

String monthLabel(String key) {
  const names = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  final parts = key.split('-');
  final month = parts.length > 1 ? int.tryParse(parts[1]) : null;
  if (month == null || month < 1 || month > 12) return key;
  return '${names[month - 1]} ${parts.first}';
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(text)),
            ],
          ),
          if (action != null)
            Align(alignment: Alignment.centerRight, child: action),
        ],
      ),
    ),
  );
}

class _MorePage extends StatelessWidget {
  const _MorePage({
    required this.controller,
    required this.apiUri,
    required this.onSelect,
    required this.onLogout,
    required this.onOpenLegal,
    required this.onDataPrivacy,
  });
  final AppController controller;
  final Uri? apiUri;
  final ValueChanged<AppSection> onSelect;
  final Future<void> Function() onLogout;
  final Future<void> Function(String path) onOpenLegal;
  final Future<void> Function() onDataPrivacy;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        controller.user?.name ?? '',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      Text(
        controller.user?.email ?? '',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 18),
      for (final value in const [
        AppSection.metrics,
        AppSection.budgets,
        AppSection.funds,
        AppSection.goals,
      ])
        Card(
          child: ListTile(
            leading: Icon(value.icon),
            title: Text(value.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onSelect(value),
          ),
        ),
      const SizedBox(height: 12),
      ListTile(
        leading: const Icon(Icons.description_outlined),
        title: const Text('Termos de Uso'),
        onTap: apiUri == null
            ? null
            : () => unawaited(onOpenLegal('/termos-de-uso')),
      ),
      ListTile(
        leading: const Icon(Icons.privacy_tip_outlined),
        title: const Text('Política de Privacidade'),
        onTap: apiUri == null
            ? null
            : () => unawaited(onOpenLegal('/politica-de-privacidade')),
      ),
      ListTile(
        leading: const Icon(Icons.manage_accounts_outlined),
        title: const Text('Meus dados e privacidade'),
        subtitle: const Text('Exportar, importar ou solicitar eliminação'),
        onTap: () => unawaited(onDataPrivacy()),
      ),
      ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('Sair'),
        onTap: () => unawaited(onLogout()),
      ),
    ],
  );
}

class _AdminOverview extends StatelessWidget {
  const _AdminOverview({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final metrics = controller.adminOverview?['metrics'];
    final values = metrics is Map ? metrics : <String, dynamic>{};
    final rawPlans = controller.adminOverview?['usersByPlan'];
    final rawDaily = controller.adminOverview?['daily'];
    final rawRoutes = controller.adminOverview?['routes'];
    final rawScopes = controller.adminOverview?['scopes'];
    final plans = rawPlans is List
        ? rawPlans.whereType<Map>().toList()
        : const <Map>[];
    final daily = rawDaily is List
        ? rawDaily.whereType<Map>().toList()
        : const <Map>[];
    final routes = rawRoutes is List
        ? rawRoutes.whereType<Map>().toList()
        : const <Map>[];
    final scopes = rawScopes is List
        ? rawScopes.whereType<Map>().toList()
        : const <Map>[];
    final scopeTransactions = scopes.fold<int>(
      0,
      (total, item) =>
          total + ((item['transactionCount'] as num?)?.toInt() ?? 0),
    );
    final scopeFunds = scopes.fold<int>(
      0,
      (total, item) => total + ((item['fundCount'] as num?)?.toInt() ?? 0),
    );
    final scopeBudgets = scopes.fold<int>(
      0,
      (total, item) => total + ((item['budgetCount'] as num?)?.toInt() ?? 0),
    );
    const labels = <String, String>{
      'totalUsers': 'Usuários cadastrados',
      'activeUsers': 'Usuários ativos',
      'admins': 'Administradores',
      'activeSessions': 'Sessões ativas',
      'dataScopes': 'Camadas de dados',
      'dsarOpen': 'Pedidos LGPD pendentes',
      'auditEvents30d': 'Eventos de auditoria (30 dias)',
      'requests7d': 'Requisições em 7 dias',
      'writes7d': 'Gravações em 7 dias',
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Indicadores agregados',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        for (final entry in labels.entries)
          Card(
            child: ListTile(
              title: Text(entry.value),
              trailing: Text('${values[entry.key] ?? '—'}'),
            ),
          ),
        if (plans.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Clientes por plano',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Card(
            child: Column(
              children: [
                for (final plan in plans)
                  ListTile(
                    title: Text('${plan['plan'] ?? 'Sem plano'}'),
                    trailing: Text('${plan['count'] ?? 0}'),
                  ),
              ],
            ),
          ),
        ],
        if (daily.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Atividade recente',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Card(
            child: Column(
              children: [
                for (final item in daily)
                  ListTile(
                    title: Text('${item['day'] ?? '—'}'),
                    subtitle: Text(
                      '${item['writes'] ?? 0} salvamento(s) · ${item['errors'] ?? 0} erro(s)',
                    ),
                    trailing: Text('${item['requests'] ?? 0} acessos'),
                  ),
              ],
            ),
          ),
        ],
        if (routes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Uso por área', style: Theme.of(context).textTheme.titleMedium),
          Card(
            child: Column(
              children: [
                for (final route in routes)
                  ListTile(
                    title: Text(_adminRouteLabel('${route['name'] ?? ''}')),
                    trailing: Text('${route['count'] ?? 0}'),
                  ),
              ],
            ),
          ),
        ],
        if (scopes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Isolamento de dados',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Camadas ativas monitoradas'),
                  trailing: Text('${scopes.length}'),
                ),
                ListTile(
                  title: const Text('Lançamentos nas camadas'),
                  trailing: Text('$scopeTransactions'),
                ),
                ListTile(
                  title: const Text('Fundos nas camadas'),
                  trailing: Text('$scopeFunds'),
                ),
                ListTile(
                  title: const Text('Orçamentos nas camadas'),
                  trailing: Text('$scopeBudgets'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: controller.busy
              ? null
              : () => unawaited(controller.refresh()),
          icon: const Icon(Icons.refresh),
          label: const Text('Atualizar'),
        ),
        OutlinedButton.icon(
          onPressed: () => unawaited(controller.logout()),
          icon: const Icon(Icons.logout),
          label: const Text('Sair'),
        ),
      ],
    );
  }
}

String _adminRouteLabel(String route) => switch (route) {
  'auth_login' => 'Login',
  'auth_logout' => 'Logout',
  'finance_read' => 'Leitura financeira',
  'finance_write' => 'Salvamento financeiro',
  'lgpd_export' => 'Exportação LGPD',
  'lgpd_erasure' => 'Pedido LGPD',
  'admin_overview' => 'Administração',
  _ => route.isEmpty ? 'Outra área' : route,
};
