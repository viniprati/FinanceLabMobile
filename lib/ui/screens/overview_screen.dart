import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/money.dart';
import '../../domain/summary.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';
import '../widgets/finance_charts.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key, required this.data, required this.summary});
  final FinanceData data;
  final FinanceSummary summary;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.md),
    children: [
      LayoutBuilder(
        builder: (context, c) {
          final chart = SectionCard(
            title: 'Últimos meses',
            subtitle: 'Receitas e saídas registradas',
            child: MonthlyChart(
              flows: summary.monthlyFlows,
              showLatestBalance: true,
            ),
          );
          final cards = [
            MetricCard(
              label: 'Saldo do mês',
              value: Money.formatBr(summary.cashBalanceCents),
              caption: 'Receitas menos despesas',
              icon: Icons.account_balance_wallet_outlined,
              tone: summary.cashBalanceCents >= 0
                  ? Colors.green
                  : Colors.deepOrange,
            ),
            MetricCard(
              label: 'Receitas',
              value: Money.formatBr(summary.incomeCents),
              caption: 'No período selecionado',
              icon: Icons.trending_up,
              tone: Colors.green,
            ),
            MetricCard(
              label: 'Despesas',
              value: Money.formatBr(summary.expensesCents),
              caption: 'No período selecionado',
              icon: Icons.trending_down,
              tone: Colors.deepOrange,
            ),
          ];
          if (c.maxWidth <=
              MediaQuery.textScalerOf(context).scale(650).clamp(650, 1100)) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                cards[0],
                const SizedBox(height: AppSpacing.sm),
                chart,
                const SizedBox(height: AppSpacing.sm),
                cards[1],
                const SizedBox(height: AppSpacing.sm),
                cards[2],
              ],
            );
          }
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    Expanded(child: cards[i]),
                    if (i < cards.length - 1)
                      const SizedBox(width: AppSpacing.sm),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              chart,
            ],
          );
        },
      ),
      const SizedBox(height: AppSpacing.md),
      SectionCard(
        title: 'Patrimônio',
        subtitle: '${data.funds.length} fundo(s) monitorado(s)',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minimumWidth = MediaQuery.textScalerOf(context)
                .scale(220)
                .clamp(220, 440);
            final columns =
                ((constraints.maxWidth + AppSpacing.sm) /
                        (minimumWidth + AppSpacing.sm))
                    .floor()
                    .clamp(1, 4);
            final cardWidth =
                (constraints.maxWidth - AppSpacing.sm * (columns - 1)) /
                columns;
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: MetricCard(
                    label: 'Carteira atual',
                    value: Money.formatBr(summary.portfolioCents),
                    icon: Icons.savings_outlined,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: MetricCard(
                    label: 'Investido',
                    value: Money.formatBr(summary.investedCents),
                    icon: Icons.account_balance_outlined,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: MetricCard(
                    label: 'Resultado da carteira',
                    value: Money.formatBr(summary.portfolioGainCents),
                    icon: Icons.show_chart_outlined,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: MetricCard(
                    label: 'Patrimônio monitorado',
                    value: Money.formatBr(summary.netWorthCents),
                    caption: 'Saldo do mês + carteira',
                    icon: Icons.assessment_outlined,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      SectionCard(
        title: 'Destino das saídas',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Gastos de consumo'),
            ReadableValueText(
              value: Money.formatBr(summary.livingExpensesCents),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text('Aportes'),
            ReadableValueText(
              value: Money.formatBr(summary.contributionsCents),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
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
                  leading: const Icon(Icons.info_outline),
                  title: Text(alert),
                ),
            ],
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      SectionCard(
        title: 'Próximos passos',
        child: data.transactions.isEmpty
            ? const EmptyState(
                message: 'Adicione seu primeiro lançamento para começar.',
                icon: Icons.add_chart_outlined,
              )
            : Text('${data.transactions.length} lançamento(s) registrados.'),
      ),
    ],
  );
}
