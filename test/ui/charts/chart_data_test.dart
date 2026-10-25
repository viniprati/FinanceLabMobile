import 'package:financelab_mobile/domain/models.dart';
import 'package:financelab_mobile/domain/summary.dart';
import 'package:financelab_mobile/ui/widgets/chart_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('historical window ends at selected month and fills calendar gaps', () {
    const flows = [
      MonthlyFlow('2025-12', 10000, 4000, 0),
      MonthlyFlow('2026-02', 0, 13000, 3000),
      MonthlyFlow('2026-03', 99999, 0, 0),
    ];
    final window = monthlyFlowWindow(flows, '2026-02', 3);
    expect(window.map((flow) => flow.month), ['2025-12', '2026-01', '2026-02']);
    expect(window.map((flow) => flow.balanceCents), [6000, 0, -13000]);
    expect(window.last.contributionsCents, 3000);
    expect(cumulativeMovementCents(window), [6000, 6000, -7000]);
  });

  test('window with no recorded movement is empty', () {
    const flows = [MonthlyFlow('2026-03', 100, 0, 0)];
    expect(monthlyFlowWindow(flows, '2026-02', 3), isEmpty);
    expect(monthlyFlowWindow(flows, 'bad', 3), isEmpty);
    expect(monthlyFlowWindow(flows, '2026-03', 0), isEmpty);
  });

  test('fund distribution adds current cents exactly and excludes zero', () {
    const funds = [
      Fund(
        id: 'a',
        name: 'A',
        account: '',
        category: 'Renda fixa',
        benchmark: '',
        liquidity: '',
        investedCents: 150000,
        currentCents: 123456789012,
        monthlyYieldCents: -42,
      ),
      Fund(
        id: 'b',
        name: 'B',
        account: '',
        category: 'Renda fixa',
        benchmark: '',
        liquidity: '',
        investedCents: 0,
        currentCents: 99,
        monthlyYieldCents: 0,
      ),
      Fund(
        id: 'c',
        name: 'C',
        account: '',
        category: 'Multimercado',
        benchmark: '',
        liquidity: '',
        investedCents: 0,
        currentCents: 0,
        monthlyYieldCents: 0,
      ),
    ];
    final distribution = currentFundsByCategory(funds);
    expect(distribution, hasLength(1));
    expect(distribution.single.key, 'Renda fixa');
    expect(distribution.single.value, 123456789111);
  });
}
