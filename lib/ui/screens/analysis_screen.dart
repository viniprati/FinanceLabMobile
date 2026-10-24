import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/money.dart';
import '../../domain/summary.dart';
import '../widgets/section_card.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key, required this.data, required this.summary});
  final FinanceData data;
  final FinanceSummary summary;
  @override
  Widget build(BuildContext context) {
    final entries = summary.categoryCents.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = entries.isEmpty ? 1 : entries.first.value;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: 'Despesas por categoria',
          subtitle: entries.isEmpty
              ? 'Sem despesas no período'
              : '${entries.length} categoria(s)',
          child: entries.isEmpty
              ? const EmptyState(
                  message: 'Adicione despesas para visualizar a distribuição.',
                  icon: Icons.pie_chart_outline,
                )
              : Column(
                  children: [
                    for (final e in entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 110,
                              child: Text(
                                e.key,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: e.value / max,
                                  minHeight: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(Money.formatBr(e.value)),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        if (data.transactions.any((t) => t.subcategory.trim().isNotEmpty)) ...[
          SectionCard(
            title: 'Despesas por subcategoria',
            child: Column(
              children: [
                for (final entry
                    in (summary.subcategoryCents.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value))))
                  ListTile(
                    title: Text(entry.key),
                    trailing: Text(Money.formatBr(entry.value)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        SectionCard(
          title: 'Histórico mensal',
          subtitle: 'Receitas, saídas e saldo registrado',
          child: summary.monthlyFlows.isEmpty
              ? const EmptyState(message: 'Ainda não há histórico mensal.')
              : Column(
                  children: [
                    for (final flow in summary.monthlyFlows.reversed.take(6))
                      ListTile(
                        title: Text(flow.month),
                        subtitle: Text(
                          'Receitas: ${Money.formatBr(flow.incomeCents)} · '
                          'Saídas: ${Money.formatBr(flow.expensesCents)}',
                        ),
                        trailing: Text(Money.formatBr(flow.balanceCents)),
                      ),
                  ],
                ),
        ),
        if (summary.budgetProgress.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: 'Uso dos orçamentos',
            child: Column(
              children: [
                for (final budget in summary.budgetProgress)
                  ListTile(
                    title: Text(budget.category),
                    subtitle: Text(
                      '${Money.formatBr(budget.spentCents)} de '
                      '${Money.formatBr(budget.limitCents)}',
                    ),
                    trailing: Text('${(budget.usage * 100).round()}%'),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        SectionCard(
          title: 'Aportes',
          child: Text(
            'Aportes no período: ${Money.formatBr(summary.contributionsCents)}',
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Dados analisados',
          child: Text(
            '${data.transactions.length} lançamento(s) e ${data.budgets.length} orçamento(s).',
          ),
        ),
      ],
    );
  }
}
