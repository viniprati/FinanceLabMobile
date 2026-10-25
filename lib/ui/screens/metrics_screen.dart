import 'package:flutter/material.dart';

import '../../domain/money.dart';
import '../../domain/models.dart';
import '../../domain/summary.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key, required this.data, required this.summary});
  final FinanceData data;
  final FinanceSummary summary;
  @override
  Widget build(BuildContext context) {
    String percentage(double? rate) =>
        rate == null ? '—' : '${(rate * 100).toStringAsFixed(1)}%';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: 'Saúde das movimentações',
          subtitle: 'Indicadores do período',
          child: Column(
            children: [
              _MetricRow(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Saldo das movimentações',
                value: Money.formatBr(summary.cashBalanceCents),
                helper: 'Receitas menos despesas; não é saldo bancário',
              ),
              const Divider(height: 24),
              _MetricRow(
                icon: Icons.savings_outlined,
                label: 'Taxa de economia',
                value: percentage(summary.savingsRate),
                helper: summary.savingsRate == null
                    ? 'Sem receitas no período'
                    : 'Percentual preservado',
              ),
              const Divider(height: 24),
              _MetricRow(
                icon: Icons.shopping_bag_outlined,
                label: 'Gastos de consumo',
                value: Money.formatBr(summary.livingExpensesCents),
                helper: 'Despesas sem aportes',
              ),
              const Divider(height: 24),
              _MetricRow(
                icon: Icons.add_circle_outline,
                label: 'Aportes no mês',
                value: Money.formatBr(summary.contributionsCents),
                helper: 'Saídas para investimentos; incluídas em despesas',
              ),
              const Divider(height: 24),
              _MetricRow(
                icon: Icons.event_available_outlined,
                label: 'Projeção de consumo',
                value: Money.formatBr(summary.projectedLivingExpensesCents),
                helper: 'No ritmo do período selecionado',
              ),
              const Divider(height: 24),
              _MetricRow(
                icon: Icons.health_and_safety_outlined,
                label: 'Cobertura da reserva',
                value: summary.emergencyCoverageMonths == null
                    ? '—'
                    : '${summary.emergencyCoverageMonths!.toStringAsFixed(1)} meses',
                helper: 'Reserva sobre gastos de consumo',
              ),
              const Divider(height: 24),
              _MetricRow(
                icon: Icons.flag_outlined,
                label: 'Fundos',
                value: '${data.funds.length}',
                helper: 'Ativos monitorados',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Carteira atual monitorada',
          subtitle: 'Valores atuais dos fundos; não é evolução histórica',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                MetricCard(
                  label: 'Atual',
                  value: Money.formatBr(summary.portfolioCents),
                ),
                MetricCard(
                  label: 'Investido',
                  value: Money.formatBr(summary.investedCents),
                ),
              ];
              if (constraints.maxWidth <=
                  MediaQuery.textScalerOf(context).scale(360).clamp(360, 800)) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [cards[0], const SizedBox(height: 12), cards[1]],
                );
              }
              return Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1]),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Desempenho dos fundos',
          child: Column(
            children: [
              _MetricRow(
                icon: Icons.trending_up,
                label: 'Resultado da carteira',
                value: Money.formatBr(summary.portfolioGainCents),
                helper: percentage(summary.portfolioReturnRate),
              ),
              const Divider(height: 24),
              _MetricRow(
                icon: Icons.payments_outlined,
                label: 'Rendimento mensal informado',
                value: Money.formatBr(summary.monthlyYieldCents),
                helper: 'Soma dos fundos cadastrados',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
  });
  final IconData icon;
  final String label, value, helper;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final labelWidget = Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(helper, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      );
      final amount = ReadableValueText(
        value: value,
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w900),
      );
      if (constraints.maxWidth < 500 ||
          MediaQuery.textScalerOf(context).scale(16) > 22) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            labelWidget,
            const SizedBox(height: AppSpacing.xs),
            Padding(padding: const EdgeInsets.only(left: 36), child: amount),
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: labelWidget),
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: amount),
        ],
      );
    },
  );
}
