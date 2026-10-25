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
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Resumo mensal', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Mês selecionado: ${summary.monthKey}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              MetricCard(
                label: 'Saldo das movimentações',
                value: Money.formatBr(summary.cashBalanceCents),
                caption: 'Receitas menos despesas; não é saldo bancário',
                icon: Icons.swap_vert_circle_outlined,
                tone: summary.cashBalanceCents >= 0
                    ? colors?.income
                    : colors?.alert,
              ),
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
                constraints.maxWidth < 700 ||
                MediaQuery.textScalerOf(context).scale(16) > 20;
            return stacked
                ? Column(
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        cards[i],
                        if (i < cards.length - 1)
                          const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        Expanded(child: cards[i]),
                        if (i < cards.length - 1)
                          const SizedBox(width: AppSpacing.sm),
                      ],
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
            flows: monthlyFlowWindow(summary.monthlyFlows, summary.monthKey, 6),
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
              : CategoryChart(entries: summary.categoryCents.entries.toList()),
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
    );
  }
}
