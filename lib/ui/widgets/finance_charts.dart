import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/money.dart';
import '../../domain/summary.dart';
import '../theme/app_theme.dart';

class CategoryChart extends StatelessWidget {
  const CategoryChart({super.key, required this.entries});
  final List<MapEntry<String, int>> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Text('Sem despesas para desenhar neste período.');
    }
    final sorted = [...entries]..sort((a, b) => b.value.compareTo(a.value));
    final top = _categorySlices(sorted);
    final total = top.fold<int>(0, (sum, entry) => sum + entry.value);
    final colors = _chartColors(context, top.length);
    final labels = top
        .asMap()
        .entries
        .map(
          (item) =>
              '${item.value.key}: ${Money.formatBr(item.value.value)}, '
              '${total == 0 ? 0 : (item.value.value / total * 100).round()}%',
        )
        .join('. ');
    return Semantics(
      container: true,
      label: 'Gráfico de despesas por categoria. $labels',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 170,
              child: CustomPaint(
                painter: _CategoryPainter(values: top, colors: colors),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < top.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xxs),
                      child: Container(width: 12, height: 12, color: colors[i]),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(top[i].key),
                          Text(
                            '${Money.formatBr(top[i].value)} · '
                            '${total == 0 ? 0 : (top[i].value / total * 100).round()}%',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (entries.length > 6)
              const Text(
                'As categorias menores foram agrupadas em “Outras categorias”.',
              ),
          ],
        ),
      ),
    );
  }
}

class MonthlyChart extends StatelessWidget {
  const MonthlyChart({
    super.key,
    required this.flows,
    this.showLatestBalance = false,
  });
  final List<MonthlyFlow> flows;
  final bool showLatestBalance;

  @override
  Widget build(BuildContext context) {
    if (flows.isEmpty) {
      return const Text('Sem histórico suficiente para desenhar.');
    }
    final visible = flows.reversed.take(6).toList().reversed.toList();
    final values = visible
        .expand((flow) => [flow.incomeCents, flow.expensesCents])
        .toList();
    final maxValue = values.isEmpty
        ? 1
        : values.reduce(math.max).clamp(1, 1 << 62);
    final labels = visible
        .map(
          (flow) =>
              '${flow.month}: receitas ${Money.formatBr(flow.incomeCents)}, '
              'saídas ${Money.formatBr(flow.expensesCents)}, '
              'saldo ${Money.formatBr(flow.balanceCents)}',
        )
        .join('. ');
    return Semantics(
      container: true,
      label: 'Gráfico mensal de receitas e saídas. $labels',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 160,
              child: CustomPaint(
                painter: _MonthlyPainter(
                  flows: visible,
                  maxValue: maxValue.toDouble(),
                  incomeColor: Theme.of(context).colorScheme.primary,
                  expenseColor: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                for (final flow in visible)
                  Expanded(
                    child: Text(
                      flow.month.substring(5),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            const Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _LegendDot(label: 'Receitas', colorRole: _ChartColor.primary),
                _LegendDot(
                  label: 'Saídas (inclui aportes)',
                  colorRole: _ChartColor.tertiary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (showLatestBalance)
              Text(
                'Saldo em ${visible.last.month}: '
                '${Money.formatBr(visible.last.balanceCents)}',
              ),
          ],
        ),
      ),
    );
  }
}

enum _ChartColor { primary, tertiary }

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.colorRole});
  final String label;
  final _ChartColor colorRole;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 250),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorRole == _ChartColor.primary
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.tertiary,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(child: Text(label)),
      ],
    ),
  );
}

class _CategoryPainter extends CustomPainter {
  _CategoryPainter({required this.values, required this.colors});
  final List<MapEntry<String, int>> values;
  final List<Color> colors;
  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<int>(0, (sum, item) => sum + item.value);
    if (total <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * .36;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i].value / total * math.pi * 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        true,
        Paint()..color = colors[i],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.colors != colors;
}

class _MonthlyPainter extends CustomPainter {
  _MonthlyPainter({
    required this.flows,
    required this.maxValue,
    required this.incomeColor,
    required this.expenseColor,
  });
  final List<MonthlyFlow> flows;
  final double maxValue;
  final Color incomeColor, expenseColor;
  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height - 2;
    final chartHeight = baseline - 8;
    final groupWidth = size.width / math.max(flows.length, 1);
    final barWidth = math.min(28.0, groupWidth * .24);
    final axis = Paint()
      ..color = incomeColor.withValues(alpha: .25)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, baseline), Offset(size.width, baseline), axis);
    for (var i = 0; i < flows.length; i++) {
      final x = groupWidth * i + groupWidth / 2;
      final incomeHeight = chartHeight * flows[i].incomeCents / maxValue;
      final expenseHeight = chartHeight * flows[i].expensesCents / maxValue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x - barWidth - 2,
            baseline - incomeHeight,
            barWidth,
            incomeHeight,
          ),
          const Radius.circular(5),
        ),
        Paint()..color = incomeColor,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x + 2,
            baseline - expenseHeight,
            barWidth,
            expenseHeight,
          ),
          const Radius.circular(5),
        ),
        Paint()..color = expenseColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyPainter oldDelegate) => true;
}

List<Color> _chartColors(BuildContext context, int count) {
  final scheme = Theme.of(context).colorScheme;
  final colors = [
    scheme.primary,
    scheme.tertiary,
    scheme.secondary,
    scheme.error,
    scheme.inversePrimary,
    scheme.outline,
  ];
  return List.generate(count, (index) => colors[index % colors.length]);
}

List<MapEntry<String, int>> _categorySlices(
  List<MapEntry<String, int>> entries,
) {
  if (entries.length <= 6) return entries;
  final top = entries.take(5).toList();
  final remainder = entries
      .skip(5)
      .fold<int>(0, (sum, entry) => sum + entry.value);
  if (remainder > 0) top.add(MapEntry('Outras categorias', remainder));
  return top;
}
