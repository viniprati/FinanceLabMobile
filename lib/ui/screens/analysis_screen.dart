import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/money.dart';
import '../../domain/summary.dart';
import '../theme/app_theme.dart';
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
      padding: const EdgeInsets.all(AppSpacing.md),
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
                      Semantics(
                        container: true,
                        label:
                            '${e.key}: ${Money.formatBr(e.value)}. '
                            '${((e.value / max) * 100).round()}% da maior categoria.',
                        child: ExcludeSemantics(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: Text(e.key)),
                                    const SizedBox(width: AppSpacing.sm),
                                    Flexible(
                                      child: Text(
                                        Money.formatBr(e.value),
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: e.value / max,
                                    minHeight: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (data.transactions.any((t) => t.subcategory.trim().isNotEmpty)) ...[
          SectionCard(
            title: 'Despesas por subcategoria',
            child: Column(
              children: [
                for (final entry
                    in (summary.subcategoryCents.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value))))
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(entry.key)),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            Money.formatBr(entry.value),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        SectionCard(
          title: 'Histórico mensal',
          subtitle: 'Receitas, saídas e saldo registrado',
          child: summary.monthlyFlows.isEmpty
              ? const EmptyState(message: 'Ainda não há histórico mensal.')
              : Column(
                  children: [
                    for (final flow in summary.monthlyFlows.reversed.take(6))
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: Text(flow.month)),
                                const SizedBox(width: AppSpacing.sm),
                                Flexible(
                                  child: Text(
                                    Money.formatBr(flow.balanceCents),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Receitas: ${Money.formatBr(flow.incomeCents)} · '
                              'Saídas: ${Money.formatBr(flow.expensesCents)}',
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        if (summary.budgetProgress.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: 'Uso dos orçamentos',
            child: Column(
              children: [
                for (final budget in summary.budgetProgress)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: Text(budget.category)),
                            const SizedBox(width: AppSpacing.sm),
                            Text('${(budget.usage * 100).round()}%'),
                          ],
                        ),
                        Text(
                          '${Money.formatBr(budget.spentCents)} de '
                          '${Money.formatBr(budget.limitCents)}',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
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
