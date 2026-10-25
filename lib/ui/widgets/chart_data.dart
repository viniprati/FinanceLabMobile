import '../../domain/models.dart';
import '../../domain/summary.dart';

/// A calendar window ending at the month selected in the app. Empty calendar
/// months are represented by zero only when the window has recorded activity.
List<MonthlyFlow> monthlyFlowWindow(
  List<MonthlyFlow> flows,
  String endMonth,
  int monthCount,
) {
  final end = _parseMonth(endMonth);
  if (end == null || monthCount <= 0) return const [];

  final start = DateTime(end.year, end.month - monthCount + 1);
  final byMonth = <String, MonthlyFlow>{};
  for (final flow in flows) {
    final month = _parseMonth(flow.month);
    if (month == null || month.isBefore(start) || month.isAfter(end)) continue;
    final previous = byMonth[flow.month];
    byMonth[flow.month] = previous == null
        ? flow
        : MonthlyFlow(
            flow.month,
            previous.incomeCents + flow.incomeCents,
            previous.expensesCents + flow.expensesCents,
            previous.contributionsCents + flow.contributionsCents,
          );
  }
  if (byMonth.isEmpty) return const [];

  final window = <MonthlyFlow>[];
  for (var offset = 0; offset < monthCount; offset++) {
    final date = DateTime(start.year, start.month + offset);
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    window.add(byMonth[key] ?? MonthlyFlow(key, 0, 0, 0));
  }
  return window;
}

/// Cumulative net movement within the supplied window, starting from zero.
/// This is not an account balance or an investment valuation.
List<int> cumulativeMovementCents(List<MonthlyFlow> flows) {
  var total = 0;
  return [for (final flow in flows) total += flow.balanceCents];
}

/// Current positive fund positions grouped by category; no historical values
/// are inferred from a fund's current and invested amounts.
List<MapEntry<String, int>> currentFundsByCategory(List<Fund> funds) {
  final totals = <String, int>{};
  for (final fund in funds) {
    if (fund.currentCents <= 0) continue;
    final category = fund.category.trim().isEmpty
        ? 'Sem categoria'
        : fund.category.trim();
    totals[category] = (totals[category] ?? 0) + fund.currentCents;
  }
  return totals.entries.toList()..sort((a, b) {
    final amountOrder = b.value.compareTo(a.value);
    return amountOrder != 0 ? amountOrder : a.key.compareTo(b.key);
  });
}

DateTime? _parseMonth(String key) {
  final match = RegExp(r'^(\d{4})-(0[1-9]|1[0-2])$').firstMatch(key);
  if (match == null) return null;
  return DateTime(int.parse(match.group(1)!), int.parse(match.group(2)!));
}
