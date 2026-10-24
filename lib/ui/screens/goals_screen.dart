import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/money.dart';
import '../../domain/summary.dart';

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
    super.dispose();
  }

  int? _amount(String s) {
    final n = Money.tryParsePtBr(s);
    return n == null || n < 0 ? null : n;
  }

  void _save() {
    if (!(_key.currentState?.validate() ?? false)) return;
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Metas financeiras',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  _field(_budget, 'Orçamento mensal'),
                  _field(_target, 'Meta da reserva'),
                  _field(_saved, 'Valor guardado'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Salvar metas'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
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
    );
  }

  Widget _field(TextEditingController c, String label) => TextFormField(
    controller: c,
    decoration: InputDecoration(labelText: '$label (R\$)'),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    validator: (v) =>
        _amount(v ?? '') == null ? 'Informe um valor válido' : null,
  );
  Widget _progress(
    BuildContext context,
    String title,
    double value,
    String detail,
  ) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: value),
          const SizedBox(height: 8),
          Text(detail),
        ],
      ),
    ),
  );
}
