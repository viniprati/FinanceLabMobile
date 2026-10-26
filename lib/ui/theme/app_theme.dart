import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class AppRadius {
  static const control = 14.0;
  static const card = 20.0;
  static const icon = 13.0;
}

/// Semantic colors used by financial states and chart marks.
///
/// These colors intentionally remain separate from [ColorScheme]: a positive
/// amount, a goal, and an alert need different visual meanings while still
/// adapting to light and dark surfaces.
@immutable
class FinanceColors extends ThemeExtension<FinanceColors> {
  const FinanceColors({
    required this.income,
    required this.expense,
    required this.contribution,
    required this.goal,
    required this.alert,
    required this.neutral,
  });

  final Color income;
  final Color expense;
  final Color contribution;
  final Color goal;
  final Color alert;
  final Color neutral;

  static const light = FinanceColors(
    income: Color(0xFF087F5B),
    expense: Color(0xFFB42318),
    contribution: Color(0xFF2563A6),
    goal: Color(0xFF6B4E9B),
    alert: Color(0xFFA15C00),
    neutral: Color(0xFF36504A),
  );

  static const dark = FinanceColors(
    income: Color(0xFF56D6A7),
    expense: Color(0xFFFF8A80),
    contribution: Color(0xFF8DBBFF),
    goal: Color(0xFFD0B6FF),
    alert: Color(0xFFFFC266),
    neutral: Color(0xFFB6CEC7),
  );

  @override
  FinanceColors copyWith({
    Color? income,
    Color? expense,
    Color? contribution,
    Color? goal,
    Color? alert,
    Color? neutral,
  }) => FinanceColors(
    income: income ?? this.income,
    expense: expense ?? this.expense,
    contribution: contribution ?? this.contribution,
    goal: goal ?? this.goal,
    alert: alert ?? this.alert,
    neutral: neutral ?? this.neutral,
  );

  @override
  FinanceColors lerp(covariant FinanceColors? other, double t) {
    if (other == null) return this;
    return FinanceColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      contribution: Color.lerp(contribution, other.contribution, t)!,
      goal: Color.lerp(goal, other.goal, t)!,
      alert: Color.lerp(alert, other.alert, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }
}

abstract final class AppTheme {
  static const seed = Color(0xFF1C6B5A);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return _build(scheme, FinanceColors.light);
  }

  static ThemeData dark() => _build(
    ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
    FinanceColors.dark,
  );

  static ThemeData _build(ColorScheme scheme, FinanceColors financeColors) {
    final refinedScheme = scheme.copyWith(
      primary: scheme.brightness == Brightness.light
          ? const Color(0xFF0B5D55)
          : const Color(0xFF4FD1C5),
      onPrimary: scheme.brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF003733),
      secondary: scheme.brightness == Brightness.light
          ? const Color(0xFF087F5B)
          : const Color(0xFF56D6A7),
      onSecondary: scheme.brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF003827),
      surface: scheme.brightness == Brightness.light
          ? const Color(0xFFF7FAF9)
          : const Color(0xFF101A18),
    );
    final typography = Typography.material2021(
      platform: TargetPlatform.android,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: refinedScheme,
      scaffoldBackgroundColor: refinedScheme.brightness == Brightness.light
          ? const Color(0xFFF0F5F3)
          : const Color(0xFF0D1513),
      textTheme: refinedScheme.brightness == Brightness.light
          ? typography.black
          : typography.white,
      extensions: [financeColors],
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: refinedScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: refinedScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: refinedScheme.primary, width: 2),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: refinedScheme.brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF172420),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: refinedScheme.brightness == Brightness.light
                ? const Color(0xFFDCE8E3)
                : const Color(0xFF2A4038),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: refinedScheme.brightness == Brightness.light
            ? const Color(0xFFF0F5F3)
            : const Color(0xFF0D1513),
        surfaceTintColor: refinedScheme.surfaceTint,
        titleTextStyle:
            (refinedScheme.brightness == Brightness.light
                    ? typography.black
                    : typography.white)
                .titleLarge
                ?.copyWith(
                  color: refinedScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(
          (refinedScheme.brightness == Brightness.light
                  ? typography.black
                  : typography.white)
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        minWidth: 76,
        minExtendedWidth: 220,
        groupAlignment: -0.9,
        labelType: NavigationRailLabelType.none,
        useIndicator: true,
      ),
    );
  }
}
