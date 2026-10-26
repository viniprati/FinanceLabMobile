import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/money.dart';
import '../../domain/summary.dart';
import '../theme/app_theme.dart';
import '../widgets/chart_data.dart';
import '../widgets/finance_charts.dart';
import '../widgets/section_card.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key, required this.data, required this.summary});
  final FinanceData data;
  final FinanceSummary summary;
  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int months = 6;
  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final flows = monthlyFlowWindow(
      summary.monthlyFlows,
      summary.monthKey,
      months,
    );
    final entries = summary.categoryCents.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final subcategories = summary.subcategoryCents.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final fundCategories = currentFundsByCategory(widget.data.funds);
    final colors = Theme.of(context).extension<FinanceColors>();
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text('Análise', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Categorias e orçamentos de ${summary.monthKey}. O histórico termina nesse mês.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'Fluxo mensal',
              subtitle:
                  '$months meses até ${summary.monthKey}. Saldo acumulado de movimentações, não bancário.',
              action: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 3, label: Text('3m')),
                  ButtonSegment(value: 6, label: Text('6m')),
                  ButtonSegment(value: 12, label: Text('12m')),
                ],
                selected: {months},
                onSelectionChanged: (v) => setState(() => months = v.first),
              ),
              child: flows.isEmpty
                  ? const EmptyState(
                      message:
                          'Sem movimentações no período histórico escolhido.',
                      icon: Icons.show_chart_outlined,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Receitas e saídas por mês',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        MonthlyChart(flows: flows),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Saldo acumulado das movimentações',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        CumulativeFlowChart(flows: flows),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'Despesas por categoria',
              subtitle: 'Despesas de consumo do mês selecionado',
              child: entries.isEmpty
                  ? const EmptyState(
                      message:
                          'Adicione despesas para visualizar as categorias.',
                      icon: Icons.bar_chart_outlined,
                    )
                  : Column(
                      children: [
                        CategoryChart(entries: entries),
                        if (entries.length > 6)
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: const Text('Ver todas as categorias'),
                            children: [
                              for (final entry in entries)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.xs,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(entry.key),
                                      Text(Money.formatBr(entry.value)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'Orçamento utilizado e disponível',
              subtitle: 'Valores em reais no mês selecionado',
              child: BudgetUseChart(budgets: summary.budgetProgress),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'Meta da reserva de emergência',
              subtitle: 'Progresso atual; não é uma série histórica',
              child: GoalProgressChart(
                savedCents: summary.emergencySavedCents,
                targetCents: summary.emergencyTargetCents,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'Distribuição atual dos fundos',
              subtitle: 'Valores atuais por categoria, sem representar evolução no tempo',
              child: Column(
                children: [
                  FundDistributionChart(funds: widget.data.funds),
                  if (fundCategories.length > 6)
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Ver todas as categorias de fundos'),
                      children: [
                        for (final entry in fundCategories)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(entry.key),
                                Text(Money.formatBr(entry.value)),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (widget.data.transactions.any(
                  (t) =>
                      t.date.startsWith(summary.monthKey) &&
                      t.subcategory.trim().isNotEmpty,
                ) &&
                subcategories.isNotEmpty)
              SectionCard(
                title: 'Subcategorias',
                child: Column(
                  children: [
                    for (final entry in subcategories)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(entry.key),
                            Text(Money.formatBr(entry.value)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.info_outline, color: colors?.neutral),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '${widget.data.transactions.length} lançamento(s), ${widget.data.budgets.length} orçamento(s) e ${widget.data.funds.length} fundo(s) analisado(s).',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
