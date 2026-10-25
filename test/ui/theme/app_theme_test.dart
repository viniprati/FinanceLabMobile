import 'package:financelab_mobile/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'financial palette is exposed consistently in both brightness modes',
    () {
      final light = AppTheme.light().extension<FinanceColors>()!;
      final dark = AppTheme.dark().extension<FinanceColors>()!;

      expect(light.income, const Color(0xFF087F5B));
      expect(light.expense, const Color(0xFFB42318));
      expect(dark.income, const Color(0xFF56D6A7));
      expect(dark.expense, const Color(0xFFFF8A80));
      expect(light.goal, isNot(light.income));
      expect(dark.alert, isNot(dark.expense));
    },
  );

  test('semantic text colors keep readable contrast on their surfaces', () {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      final colors = theme.extension<FinanceColors>()!;
      for (final surface in [
        theme.colorScheme.surface,
        theme.cardTheme.color!,
      ]) {
        for (final color in [
          colors.income,
          colors.expense,
          colors.contribution,
          colors.goal,
          colors.alert,
          colors.neutral,
        ]) {
          final lighter = color.computeLuminance() > surface.computeLuminance()
              ? color
              : surface;
          final darker = identical(lighter, color) ? surface : color;
          final ratio =
              (lighter.computeLuminance() + .05) /
              (darker.computeLuminance() + .05);
          expect(ratio, greaterThanOrEqualTo(4.5));
        }
      }
    }
  });
}
