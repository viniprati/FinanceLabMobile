import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/money.dart';
import '../../domain/summary.dart';
import '../theme/app_theme.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({
    super.key,
    required this.data,
    this.summary,
    required this.onDataChanged,
  });
  final FinanceData data;
  final FinanceSummary? summary;
  final ValueChanged<FinanceData> onDataChanged;
  @override
  State<GoalsScreen> createState() => _GoalsState();
}

class _GoalsState extends State<GoalsScreen> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _budget, _target, _saved;
  final _budgetFocus = FocusNode();
  final _targetFocus = FocusNode();
  final _savedFocus = FocusNode();
  @override
  void initState() {
    super.initState();
    _budget = TextEditingController(
      text: Money.formatBr(widget.data.goals.monthlyBudgetCents),
    );
    _target = TextEditingController(
      text: Money.formatBr(widget.data.goals.emergencyFundCents),
    );
    _saved = TextEditingController(
      text: Money.formatBr(widget.data.goals.emergencySavedCents),
    );
  }

  @override
  void didUpdateWidget(covariant GoalsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.goals != widget.data.goals) {
      _budget.text = Money.formatBr(widget.data.goals.monthlyBudgetCents);
      _target.text = Money.formatBr(widget.data.goals.emergencyFundCents);
      _saved.text = Money.formatBr(widget.data.goals.emergencySavedCents);
    }
  }

  @override
  void dispose() {
    _budget.dispose();
    _target.dispose();
    _saved.dispose();
    _budgetFocus.dispose();
    _targetFocus.dispose();
    _savedFocus.dispose();
    super.dispose();
  }

  int? _amount(String s) {
    final n = Money.tryParsePtBr(s);
    return n == null || n < 0 ? null : n;
  }

  void _save() {
    if (!(_key.currentState?.validate() ?? false)) {
      final target = _amount(_budget.text) == null
          ? _budgetFocus
          : _amount(_target.text) == null
          ? _targetFocus
          : _savedFocus;
      target.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || target.context == null) return;
        Scrollable.ensureVisible(
          target.context!,
          alignment: .2,
          duration: const Duration(milliseconds: 200),
        );
      });
      return;
    }
    final target = _amount(_target.text)!;
    final saved = _amount(_saved.text)!;
    widget.onDataChanged(
      widget.data.copyWith(
        goals: Goals(
          monthlyBudgetCents: _amount(_budget.text)!,
          emergencyFundCents: target,
          emergencySavedCents: saved,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.data.goals;
    final budgetProgress = g.monthlyBudgetCents == 0
        ? 0.0
        : ((widget.summary?.expensesCents ?? 0) / g.monthlyBudgetCents).clamp(
            0.0,
            1.0,
          );
    final emergencyProgress = g.emergencyFundCents == 0
        ? 0.0
        : (g.emergencySavedCents / g.emergencyFundCents).clamp(0.0, 1.0);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _key,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Metas financeiras',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _field(
                        _budget,
                        'Orçamento mensal',
                        _budgetFocus,
                        TextInputAction.next,
                        () => _targetFocus.requestFocus(),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _field(
                        _target,
                        'Meta da reserva',
                        _targetFocus,
                        TextInputAction.next,
                        () => _savedFocus.requestFocus(),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _field(
                        _saved,
                        'Valor guardado',
                        _savedFocus,
                        TextInputAction.done,
                        _save,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: _save,
                        child: const Text('Salvar metas'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _progress(
              context,
              'Orçamento mensal',
              budgetProgress,
              '${Money.formatBr(widget.summary?.expensesCents ?? 0)} usados de ${Money.formatBr(g.monthlyBudgetCents)}',
            ),
            _progress(
              context,
              'Reserva de emergência',
              emergencyProgress,
              '${Money.formatBr(g.emergencySavedCents)} guardados de ${Money.formatBr(g.emergencyFundCents)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    FocusNode focus,
    TextInputAction action,
    VoidCallback submit,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '$label (R\$)',
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: AppSpacing.xs),
      Semantics(
        label: '$label em reais',
        child: TextFormField(
          controller: c,
          focusNode: focus,
          textInputAction: action,
          onFieldSubmitted: (_) => submit(),
          decoration: const InputDecoration(hintText: 'R\$ 0,00'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) =>
              _amount(v ?? '') == null ? 'Informe um valor válido' : null,
        ),
      ),
    ],
  );
  Widget _progress(
    BuildContext context,
    String title,
    double value,
    String detail,
  ) => Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(value: value),
          const SizedBox(height: AppSpacing.sm),
          Text(detail),
        ],
      ),
    ),
  );
}
