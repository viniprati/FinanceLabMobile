import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/money.dart';
import '../../domain/summary.dart';
import '../theme/app_theme.dart';
import 'chart_data.dart';
import 'section_card.dart';

FinanceColors _colors(BuildContext context) =>
    Theme.of(context).extension<FinanceColors>() ??
    (Theme.of(context).brightness == Brightness.dark
        ? FinanceColors.dark
        : FinanceColors.light);

class _EmptyChart extends StatelessWidget {
  const _EmptyChart(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    child: Row(
      children: [
        Icon(
          Icons.insights_outlined,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

class CategoryChart extends StatefulWidget {
  const CategoryChart({
    super.key,
    required this.entries,
    this.semanticTitle = 'Despesas por categoria',
    this.barColor,
  });
  final List<MapEntry<String, int>> entries;
  final String semanticTitle;
  final Color? barColor;
  @override
  State<CategoryChart> createState() => _CategoryChartState();
}

class _CategoryChartState extends State<CategoryChart> {
  String? selectedCategory;
  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.entries]
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.isEmpty) {
      return const _EmptyChart(
        'Sem despesas de consumo no período selecionado.',
      );
    }
    final shown = _categorySlices(sorted);
    final total = shown.fold<int>(0, (sum, item) => sum + item.value);
    final labels = shown
        .map((e) => '${e.key}: ${Money.formatBr(e.value)}')
        .join('. ');
    return Semantics(
      container: true,
      label:
          '${widget.semanticTitle}, ordenadas do maior para o menor. $labels',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < shown.length; i++)
            Semantics(
              button: true,
              label:
                  '${shown[i].key}: ${Money.formatBr(shown[i].value)}, ${total == 0 ? 0 : (shown[i].value / total * 100).round()}%',
              child: InkWell(
                onTap: () => setState(() {
                  selectedCategory = selectedCategory == shown[i].key
                      ? null
                      : shown[i].key;
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xs / 2,
                  ),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final fraction = total <= 0
                          ? 0.0
                          : shown[i].value / total;
                      final compact =
                          c.maxWidth < 380 ||
                          MediaQuery.textScalerOf(context).scale(14) > 18;
                      final amount = Money.formatBr(shown[i].value);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (compact) ...[
                            Text(
                              shown[i].key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            ReadableValueText(value: amount),
                          ] else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    shown[i].key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Flexible(
                                  child: Text(amount, textAlign: TextAlign.end),
                                ),
                              ],
                            ),
                          const SizedBox(height: AppSpacing.xxs),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CustomPaint(
                              size: Size(c.maxWidth, 14),
                              painter: _HorizontalBarPainter(
                                fraction: fraction,
                                color:
                                    widget.barColor ?? _colors(context).expense,
                                track: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                              ),
                            ),
                          ),
                          if (selectedCategory == shown[i].key)
                            Text(
                              '${(fraction * 100).round()}% do total',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          if (widget.entries.length > 6)
            const Text(
              'As categorias menores foram agrupadas em “Outras categorias”.',
            ),
        ],
      ),
    );
  }
}

class MonthlyChart extends StatefulWidget {
  const MonthlyChart({
    super.key,
    required this.flows,
    this.showLatestBalance = false,
  });
  final List<MonthlyFlow> flows;
  final bool showLatestBalance;
  @override
  State<MonthlyChart> createState() => _MonthlyChartState();
}

class _MonthlyChartState extends State<MonthlyChart> {
  String? selectedMonth;
  @override
  Widget build(BuildContext context) {
    if (widget.flows.isEmpty) {
      return const _EmptyChart(
        'Ainda não há movimentações mensais suficientes.',
      );
    }
    final visible = widget.flows;
    final labels = visible
        .map(
          (f) =>
              '${f.month}: receitas ${Money.formatBr(f.incomeCents)}, gastos de consumo ${Money.formatBr(f.expensesCents - f.contributionsCents)}, aportes ${Money.formatBr(f.contributionsCents)}, saídas totais ${Money.formatBr(f.expensesCents)}',
        )
        .join('. ');
    final active = visible
        .where((flow) => flow.month == selectedMonth)
        .firstOrNull;
    return Semantics(
      container: true,
      label: 'Receitas e saídas por mês, em reais. $labels',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final plotWidth = math.max(
                constraints.maxWidth,
                visible.length * 40.0,
              );
              final plotHeight = (constraints.maxWidth * .48).clamp(
                150.0,
                220.0,
              );
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: plotWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: plotHeight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (d) {
                            final index =
                                ((d.localPosition.dx / plotWidth) *
                                        visible.length)
                                    .floor()
                                    .clamp(0, visible.length - 1);
                            final month = visible[index].month;
                            setState(() {
                              selectedMonth = selectedMonth == month
                                  ? null
                                  : month;
                            });
                          },
                          child: CustomPaint(
                            painter: _MonthlyPainter(
                              flows: visible,
                              colors: _colors(context),
                              scheme: Theme.of(context).colorScheme,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (final flow in visible)
                            SizedBox(
                              width: plotWidth / visible.length,
                              child: Text(
                                flow.month.substring(5),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Valores em R\$; zero indica mês sem registro. Toque nas barras ou selecione um mês.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Wrap(
            spacing: AppSpacing.xxs,
            runSpacing: AppSpacing.xxs,
            children: [
              for (final flow in visible)
                Semantics(
                  container: true,
                  button: true,
                  selected: selectedMonth == flow.month,
                  label: 'Selecionar ${flow.month}',
                  onTap: () => setState(() {
                    selectedMonth = selectedMonth == flow.month
                        ? null
                        : flow.month;
                  }),
                  child: ExcludeSemantics(
                    child: ChoiceChip(
                      label: Text(flow.month.substring(5)),
                      selected: selectedMonth == flow.month,
                      onSelected: (_) => setState(() {
                        selectedMonth = selectedMonth == flow.month
                            ? null
                            : flow.month;
                      }),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _LegendDot('Receitas', _ChartLegend.income),
              _LegendDot('Gastos de consumo', _ChartLegend.expense),
              _LegendDot('Aportes', _ChartLegend.contribution),
            ],
          ),
          if (active != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                '${active.month}: receitas ${Money.formatBr(active.incomeCents)} · gastos de consumo ${Money.formatBr(active.expensesCents - active.contributionsCents)} · aportes ${Money.formatBr(active.contributionsCents)} · saídas totais ${Money.formatBr(active.expensesCents)}',
              ),
            ),
          if (widget.showLatestBalance)
            Text(
              'Saldo das movimentações em ${visible.last.month}: ${Money.formatBr(visible.last.balanceCents)}',
            ),
        ],
      ),
    );
  }
}

class CumulativeFlowChart extends StatefulWidget {
  const CumulativeFlowChart({super.key, required this.flows});
  final List<MonthlyFlow> flows;
  @override
  State<CumulativeFlowChart> createState() => _CumulativeFlowChartState();
}

class _CumulativeFlowChartState extends State<CumulativeFlowChart> {
  String? selectedMonth;
  @override
  Widget build(BuildContext context) {
    if (widget.flows.isEmpty) {
      return const _EmptyChart(
        'Sem movimentações para calcular o saldo acumulado.',
      );
    }
    final values = cumulativeMovementCents(widget.flows);
    final selectedIndex = widget.flows.indexWhere(
      (flow) => flow.month == selectedMonth,
    );
    final labels = widget.flows
        .asMap()
        .entries
        .map(
          (e) =>
              '${e.value.month}: saldo acumulado ${Money.formatBr(values[e.key])}',
        )
        .join('. ');
    return Semantics(
      container: true,
      label:
          'Saldo acumulado das movimentações, não representa saldo bancário ou patrimônio. $labels',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final plotWidth = math.max(
                constraints.maxWidth,
                values.length * 40.0,
              );
              final plotHeight = (constraints.maxWidth * .48).clamp(
                150.0,
                220.0,
              );
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: plotWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: plotHeight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (d) {
                            final index =
                                ((d.localPosition.dx / plotWidth) *
                                        values.length)
                                    .floor()
                                    .clamp(0, values.length - 1);
                            final month = widget.flows[index].month;
                            setState(() {
                              selectedMonth = selectedMonth == month
                                  ? null
                                  : month;
                            });
                          },
                          child: CustomPaint(
                            painter: _LinePainter(
                              values: values,
                              color: _colors(context).contribution,
                              negativeColor: _colors(context).expense,
                              zeroColor: _colors(context).neutral,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (final flow in widget.flows)
                            SizedBox(
                              width: plotWidth / values.length,
                              child: Text(
                                flow.month.substring(5),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Text(
            'Linha de referência: R\$ 0,00. Valores negativos aparecem abaixo da linha.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Wrap(
            spacing: AppSpacing.xxs,
            runSpacing: AppSpacing.xxs,
            children: [
              for (final flow in widget.flows)
                Semantics(
                  container: true,
                  button: true,
                  selected: selectedMonth == flow.month,
                  label: 'Selecionar ${flow.month}',
                  onTap: () => setState(() {
                    selectedMonth = selectedMonth == flow.month
                        ? null
                        : flow.month;
                  }),
                  child: ExcludeSemantics(
                    child: ChoiceChip(
                      label: Text(flow.month.substring(5)),
                      selected: selectedMonth == flow.month,
                      onSelected: (_) => setState(() {
                        selectedMonth = selectedMonth == flow.month
                            ? null
                            : flow.month;
                      }),
                    ),
                  ),
                ),
            ],
          ),
          if (selectedIndex >= 0)
            Text(
              '${widget.flows[selectedIndex].month}: ${Money.formatBr(values[selectedIndex])}',
            ),
        ],
      ),
    );
  }
}

class BudgetUseChart extends StatelessWidget {
  const BudgetUseChart({super.key, required this.budgets});
  final List<BudgetProgress> budgets;
  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) {
      return const _EmptyChart(
        'Nenhum orçamento com limite positivo neste período.',
      );
    }
    final sorted = [...budgets]..sort((a, b) => b.usage.compareTo(a.usage));
    return Semantics(
      container: true,
      label: 'Orçamento utilizado e disponível por categoria.',
      child: Column(
        children: [
          for (final b in sorted)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    b.category,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text('${(b.usage * 100).round()}% do limite usado'),
                  const SizedBox(height: AppSpacing.xxs),
                  LinearProgressIndicator(
                    value: b.usage.clamp(0, 1).toDouble(),
                    minHeight: 10,
                    color: b.usage >= 1
                        ? _colors(context).alert
                        : _colors(context).income,
                  ),
                  Text(
                    b.remainingCents >= 0
                        ? '${Money.formatBr(b.spentCents)} usados · ${Money.formatBr(b.remainingCents)} disponíveis'
                        : '${Money.formatBr(b.spentCents)} usados · ${Money.formatBr(-b.remainingCents)} acima do limite',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class GoalProgressChart extends StatelessWidget {
  const GoalProgressChart({
    super.key,
    required this.savedCents,
    required this.targetCents,
  });
  final int savedCents, targetCents;
  @override
  Widget build(BuildContext context) {
    if (targetCents <= 0) {
      return const _EmptyChart(
        'Defina um objetivo positivo para visualizar o progresso.',
      );
    }
    final fraction = (savedCents / targetCents).clamp(0, 1).toDouble();
    return Semantics(
      container: true,
      label:
          'Progresso da meta: ${Money.formatBr(savedCents)} de ${Money.formatBr(targetCents)}, ${(savedCents / targetCents * 100).round()}%.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: fraction,
            minHeight: 12,
            color: _colors(context).goal,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${Money.formatBr(savedCents)} de ${Money.formatBr(targetCents)} · ${(savedCents / targetCents * 100).round()}%',
          ),
        ],
      ),
    );
  }
}

class FundDistributionChart extends StatelessWidget {
  const FundDistributionChart({super.key, required this.funds});
  final List<Fund> funds;
  @override
  Widget build(BuildContext context) {
    final entries = currentFundsByCategory(funds);
    if (entries.isEmpty) {
      return _EmptyChart(
        funds.isEmpty
            ? 'Cadastre fundos para visualizar a distribuição atual por categoria.'
            : 'Os fundos cadastrados não têm valores atuais positivos para distribuir por categoria.',
      );
    }
    return CategoryChart(
      entries: entries,
      semanticTitle: 'Valores atuais dos fundos por categoria',
      barColor: _colors(context).contribution,
    );
  }
}

enum _ChartLegend { income, expense, contribution }

class _LegendDot extends StatelessWidget {
  const _LegendDot(this.label, this.role);
  final String label;
  final _ChartLegend role;
  @override
  Widget build(BuildContext context) {
    final c = _colors(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: switch (role) {
                _ChartLegend.income => c.income,
                _ChartLegend.expense => c.expense,
                _ChartLegend.contribution => c.contribution,
              },
            ),
          ),
          const SizedBox(width: 6),
          Flexible(child: Text(label)),
        ],
      ),
    );
  }
}

class _HorizontalBarPainter extends CustomPainter {
  _HorizontalBarPainter({
    required this.fraction,
    required this.color,
    required this.track,
  });
  final double fraction;
  final Color color, track;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6)),
      Paint()..color = track,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * fraction, size.height),
        const Radius.circular(6),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _HorizontalBarPainter old) =>
      old.fraction != fraction || old.color != color;
}

class _MonthlyPainter extends CustomPainter {
  _MonthlyPainter({
    required this.flows,
    required this.colors,
    required this.scheme,
  });
  final List<MonthlyFlow> flows;
  final FinanceColors colors;
  final ColorScheme scheme;
  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = flows
        .expand((f) => [f.incomeCents, f.expensesCents])
        .fold<int>(1, math.max)
        .toDouble();
    final group = size.width / flows.length;
    final width = math.min(28.0, group * .24).toDouble();
    final base = size.height - 8;
    for (var i = 0; i < flows.length; i++) {
      final x = group * i + group / 2;
      final ih = (base * flows[i].incomeCents / maxValue).toDouble();
      final eh = (base * flows[i].expensesCents / maxValue).toDouble();
      final contributionHeight =
          (base *
                  flows[i].contributionsCents.clamp(0, flows[i].expensesCents) /
                  maxValue)
              .toDouble();
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - width - 2, base - ih, width, ih),
          const Radius.circular(5),
        ),
        Paint()..color = colors.income,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 2, base - eh, width, eh),
          const Radius.circular(5),
        ),
        Paint()..color = colors.expense,
      );
      if (contributionHeight > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 2, base - eh, width, contributionHeight),
            const Radius.circular(5),
          ),
          Paint()..color = colors.contribution,
        );
      }
    }
    canvas.drawLine(
      Offset(0, base),
      Offset(size.width, base),
      Paint()..color = scheme.outlineVariant,
    );
  }

  @override
  bool shouldRepaint(covariant _MonthlyPainter old) => true;
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.values,
    required this.color,
    required this.negativeColor,
    required this.zeroColor,
  });
  final List<int> values;
  final Color color, negativeColor, zeroColor;
  @override
  void paint(Canvas canvas, Size size) {
    final minV = math.min(0, values.reduce(math.min));
    final maxV = math.max(0, values.reduce(math.max));
    final range = math.max(1, maxV - minV).toDouble();
    double y(int v) =>
        size.height - ((v - minV) / range) * (size.height - 16) - 8;
    final zero = y(0);
    canvas.drawLine(
      Offset(0, zero),
      Offset(size.width, zero),
      Paint()..color = zeroColor,
    );
    final p = Path();
    for (var i = 0; i < values.length; i++) {
      final x = (i + .5) * size.width / values.length;
      final point = Offset(x, y(values[i]));
      if (i == 0) {
        p.moveTo(point.dx, point.dy);
      } else {
        p.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      p,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
    for (var i = 0; i < values.length; i++) {
      final x = (i + .5) * size.width / values.length;
      canvas.drawCircle(
        Offset(x, y(values[i])),
        4,
        Paint()..color = values[i] < 0 ? negativeColor : color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => true;
}

List<MapEntry<String, int>> _categorySlices(
  List<MapEntry<String, int>> entries,
) {
  if (entries.length <= 6) return entries;
  final top = entries.take(5).toList();
  final remainder = entries.skip(5).fold<int>(0, (sum, e) => sum + e.value);
  if (remainder > 0) top.add(MapEntry('Outras categorias', remainder));
  return top;
}
