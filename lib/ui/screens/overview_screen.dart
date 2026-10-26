import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/money.dart';
import '../../domain/summary.dart';
import '../theme/app_theme.dart';
import '../widgets/chart_data.dart';
import '../widgets/finance_charts.dart';
import '../widgets/section_card.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key, required this.data, required this.summary});
  final FinanceData data;
  final FinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FinanceColors>();
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Resumo mensal',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Mês selecionado: ${summary.monthKey}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final balanceCard = _BalanceCard(
                  value: Money.formatBr(summary.cashBalanceCents),
                  tone: summary.cashBalanceCents >= 0
                      ? colors?.income
                      : colors?.alert,
                  positive: summary.cashBalanceCents >= 0,
                );
                final flowCards = [
                  MetricCard(
                    label: 'Receitas',
                    value: Money.formatBr(summary.incomeCents),
                    caption: 'No mês selecionado',
                    icon: Icons.trending_up,
                    tone: colors?.income,
                  ),
                  MetricCard(
                    label: 'Despesas',
                    value: Money.formatBr(summary.expensesCents),
                    caption: 'Inclui aportes',
                    icon: Icons.trending_down,
                    tone: colors?.expense,
                  ),
                ];
                final stacked =
                    constraints.maxWidth < 760 ||
                    MediaQuery.textScalerOf(context).scale(16) > 20;
                final supportCards = stacked
                    ? Column(
                        children: [
                          flowCards[0],
                          const SizedBox(height: AppSpacing.sm),
                          flowCards[1],
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: flowCards[0]),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: flowCards[1]),
                        ],
                      );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    balanceCard,
                    const SizedBox(height: AppSpacing.sm),
                    supportCards,
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'Receitas e saídas por mês',
              subtitle:
                  '6 meses até ${summary.monthKey}; zero indica mês sem registro',
              child: MonthlyChart(
                flows: monthlyFlowWindow(
                  summary.monthlyFlows,
                  summary.monthKey,
                  6,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'Despesas de consumo por categoria',
              subtitle: 'Somente o mês selecionado',
              child: summary.categoryCents.isEmpty
                  ? const EmptyState(
                      message: 'Ainda não há despesas de consumo neste mês.',
                      icon: Icons.bar_chart_outlined,
                    )
                  : CategoryChart(
                      entries: summary.categoryCents.entries.toList(),
                    ),
            ),
            if (summary.alerts.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              SectionCard(
                title: 'Pontos de atenção',
                child: Column(
                  children: [
                    for (final alert in summary.alerts)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.warning_amber_rounded,
                          color: colors?.alert,
                        ),
                        title: Text(alert),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              '${data.transactions.length} lançamento(s) registrado(s) · ${data.funds.length} fundo(s) monitorado(s)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.value, required this.positive, this.tone});

  final String value;
  final bool positive;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Semantics(
        container: true,
        label:
            'Saldo das movimentações: $value. Receitas menos despesas; não é saldo bancário',
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: scheme.surface,
                      foregroundColor: tone ?? scheme.primary,
                      child: Icon(
                        positive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Saldo das movimentações',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ReadableValueText(
                  value: value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Receitas menos despesas; não é saldo bancário',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
