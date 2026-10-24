import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/money.dart';
import '../../domain/summary.dart';
import '../widgets/section_card.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key, required this.data, required this.summary});
  final FinanceData data;
  final FinanceSummary summary;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      LayoutBuilder(
        builder: (context, c) => GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: c.maxWidth > 650 ? 3 : 1,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: c.maxWidth > 650 ? 1.9 : 2.0,
          children: [
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
          ],
        ),
      ),
      const SizedBox(height: 16),
      SectionCard(
        title: 'Patrimônio',
        subtitle: '${data.funds.length} fundo(s) monitorado(s)',
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 220,
              child: MetricCard(
                label: 'Carteira atual',
                value: Money.formatBr(summary.portfolioCents),
                icon: Icons.savings_outlined,
              ),
            ),
            SizedBox(
              width: 220,
              child: MetricCard(
                label: 'Investido',
                value: Money.formatBr(summary.investedCents),
                icon: Icons.account_balance_outlined,
              ),
            ),
            SizedBox(
              width: 220,
              child: MetricCard(
                label: 'Resultado da carteira',
                value: Money.formatBr(summary.portfolioGainCents),
                icon: Icons.show_chart_outlined,
              ),
            ),
            SizedBox(
              width: 220,
              child: MetricCard(
                label: 'Patrimônio monitorado',
                value: Money.formatBr(summary.netWorthCents),
                caption: 'Saldo do mês + carteira',
                icon: Icons.assessment_outlined,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      SectionCard(
        title: 'Destino das saídas',
        child: Column(
          children: [
            ListTile(
              title: const Text('Gastos de consumo'),
              trailing: Text(Money.formatBr(summary.livingExpensesCents)),
            ),
            ListTile(
              title: const Text('Aportes'),
              trailing: Text(Money.formatBr(summary.contributionsCents)),
            ),
          ],
        ),
      ),
      if (summary.alerts.isNotEmpty) ...[
        const SizedBox(height: 16),
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
      const SizedBox(height: 16),
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
