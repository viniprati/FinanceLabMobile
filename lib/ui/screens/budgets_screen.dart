import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models.dart';
import '../../domain/money.dart';
import '../../domain/summary.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({
    super.key,
    required this.data,
    this.summary,
    required this.onDataChanged,
  });
  final FinanceData data;
  final FinanceSummary? summary;
  final ValueChanged<FinanceData> onDataChanged;
  @override
  State<BudgetsScreen> createState() => _BudgetsState();
}

class _BudgetsState extends State<BudgetsScreen> {
  final _key = GlobalKey<FormState>();
  final _cat = TextEditingController();
  final _limit = TextEditingController();
  String? _editing;
  @override
  void dispose() {
    _cat.dispose();
    _limit.dispose();
    super.dispose();
  }

  int? _amount(String s) {
    final n = Money.tryParsePtBr(s);
    return n == null || n <= 0 ? null : n;
  }

  void _save() {
    if (!(_key.currentState?.validate() ?? false)) return;
    final cat = _cat.text.trim();
    final amount = _amount(_limit.text)!;
    if (widget.data.budgets.any(
      (b) => b.id != _editing && b.category.toLowerCase() == cat.toLowerCase(),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Já existe um orçamento para essa categoria.'),
        ),
      );
      return;
    }
    final next = [...widget.data.budgets];
    final item = Budget(
      id: _editing ?? const Uuid().v4(),
      category: cat,
      monthlyLimitCents: amount,
    );
    final i = next.indexWhere((b) => b.id == _editing);
    if (i < 0) {
      next.add(item);
    } else {
      next[i] = item;
    }
    widget.onDataChanged(widget.data.copyWith(budgets: next));
    setState(() {
      _editing = null;
      _cat.clear();
      _limit.clear();
    });
  }

  void _edit(Budget b) => setState(() {
    _editing = b.id;
    _cat.text = b.category;
    _limit.text = Money.formatBr(b.monthlyLimitCents);
  });
  Future<void> _remove(Budget b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remover orçamento?'),
        content: Text(b.category),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (ok == true) {
      widget.onDataChanged(
        widget.data.copyWith(
          budgets: widget.data.budgets.where((x) => x.id != b.id).toList(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
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
                  _editing == null ? 'Novo orçamento' : 'Editar orçamento',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextFormField(
                  controller: _cat,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Informe a categoria'
                      : null,
                ),
                TextFormField(
                  controller: _limit,
                  decoration: const InputDecoration(
                    labelText: 'Limite mensal (R\$)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) => _amount(v ?? '') == null
                      ? 'Informe um valor maior que zero'
                      : null,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _save,
                  child: Text(_editing == null ? 'Adicionar' : 'Salvar'),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      if (widget.data.budgets.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('Nenhum orçamento cadastrado ainda.'),
          ),
        ),
      for (final b in widget.data.budgets) _card(context, b),
    ],
  );
  Widget _card(BuildContext context, Budget b) {
    final spent = widget.summary?.categoryCents[b.category] ?? 0;
    final ratio = b.monthlyLimitCents <= 0
        ? 0.0
        : (spent / b.monthlyLimitCents).clamp(0.0, 1.0);
    final remaining = b.monthlyLimitCents - spent;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    b.category,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Editar',
                  onPressed: () => _edit(b),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Remover',
                  onPressed: () => _remove(b),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            Text(
              '${Money.formatBr(spent)} usados de ${Money.formatBr(b.monthlyLimitCents)}',
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: ratio),
            const SizedBox(height: 6),
            Text(
              remaining >= 0
                  ? '${Money.formatBr(remaining)} restantes'
                  : '${Money.formatBr(-remaining)} acima do limite',
              style: TextStyle(
                color: remaining >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
