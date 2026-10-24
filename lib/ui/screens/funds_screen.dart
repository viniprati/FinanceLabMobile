import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models.dart';
import '../../domain/money.dart';
import '../../domain/summary.dart';

class FundsScreen extends StatefulWidget {
  const FundsScreen({
    super.key,
    required this.data,
    this.summary,
    required this.onDataChanged,
  });
  final FinanceData data;
  final FinanceSummary? summary;
  final ValueChanged<FinanceData> onDataChanged;
  @override
  State<FundsScreen> createState() => _FundsState();
}

class _FundsState extends State<FundsScreen> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _account = TextEditingController();
  final _category = TextEditingController(text: 'Renda fixa');
  final _benchmark = TextEditingController(text: 'CDI');
  final _liquidity = TextEditingController();
  final _invested = TextEditingController();
  final _current = TextEditingController();
  final _yield = TextEditingController();
  String? _editing;
  @override
  void dispose() {
    for (final c in [
      _name,
      _account,
      _category,
      _benchmark,
      _liquidity,
      _invested,
      _current,
      _yield,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _amount(String s, {bool allowNegative = false}) {
    final n = Money.tryParsePtBr(s);
    return n == null || (!allowNegative && n < 0) ? null : n;
  }

  void _save() {
    if (!(_key.currentState?.validate() ?? false)) return;
    final item = Fund(
      id: _editing ?? const Uuid().v4(),
      name: _name.text.trim(),
      account: _account.text.trim(),
      category: _category.text.trim(),
      benchmark: _benchmark.text.trim(),
      liquidity: _liquidity.text.trim(),
      investedCents: _amount(_invested.text)!,
      currentCents: _amount(_current.text)!,
      monthlyYieldCents: _yield.text.trim().isEmpty
          ? 0
          : _amount(_yield.text, allowNegative: true)!,
    );
    final next = [...widget.data.funds];
    final i = next.indexWhere((x) => x.id == _editing);
    if (i < 0) {
      next.add(item);
    } else {
      next[i] = item;
    }
    widget.onDataChanged(widget.data.copyWith(funds: next));
    setState(() {
      _editing = null;
      for (final c in [
        _name,
        _account,
        _liquidity,
        _invested,
        _current,
        _yield,
      ]) {
        c.clear();
      }
    });
  }

  void _edit(Fund f) => setState(() {
    _editing = f.id;
    _name.text = f.name;
    _account.text = f.account;
    _category.text = f.category;
    _benchmark.text = f.benchmark;
    _liquidity.text = f.liquidity;
    _invested.text = Money.formatBr(f.investedCents);
    _current.text = Money.formatBr(f.currentCents);
    _yield.text = Money.formatBr(f.monthlyYieldCents);
  });
  Future<void> _remove(Fund f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remover fundo?'),
        content: Text(f.name),
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
          funds: widget.data.funds.where((x) => x.id != f.id).toList(),
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
                  _editing == null ? 'Novo fundo' : 'Editar fundo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _field(_name, 'Nome', required: true),
                _field(_account, 'Conta ou corretora'),
                _field(_category, 'Categoria', required: true),
                _field(_benchmark, 'Benchmark'),
                _field(_liquidity, 'Liquidez'),
                _money(_invested, 'Valor aplicado', required: true),
                _money(_current, 'Valor atual', required: true),
                _money(_yield, 'Rendimento mensal', allowNegative: true),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _save,
                  child: Text(_editing == null ? 'Adicionar' : 'Salvar'),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      if (widget.data.funds.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('Nenhum fundo cadastrado ainda.'),
          ),
        ),
      for (final f in widget.data.funds) _card(context, f),
    ],
  );
  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
  }) => TextFormField(
    controller: c,
    decoration: InputDecoration(labelText: label),
    validator: required
        ? (v) => v == null || v.trim().isEmpty ? 'Informe $label' : null
        : null,
  );
  Widget _money(
    TextEditingController c,
    String label, {
    bool required = false,
    bool allowNegative = false,
  }) => TextFormField(
    controller: c,
    decoration: InputDecoration(labelText: '$label (R\$)'),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    validator: (v) {
      if (v == null || v.trim().isEmpty) {
        return required ? 'Informe $label' : null;
      }
      return _amount(v, allowNegative: allowNegative) == null
          ? 'Informe um valor válido'
          : null;
    },
  );
  Widget _card(BuildContext context, Fund f) {
    final result = f.currentCents - f.investedCents;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(f.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${f.account.isEmpty ? f.category : f.account} · ${Money.formatBr(f.currentCents)}',
            ),
            Text('Resultado: ${Money.formatBr(result)}'),
          ],
        ),
        trailing: Wrap(
          children: [
            IconButton(
              tooltip: 'Editar',
              onPressed: () => _edit(f),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Remover',
              onPressed: () => _remove(f),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        isThreeLine: true,
        leading: CircleAvatar(child: Text(result >= 0 ? '+' : '−')),
      ),
    );
  }
}
