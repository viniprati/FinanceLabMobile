import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models.dart';
import '../../domain/money.dart';
import '../../domain/summary.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

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
  final _focuses = List.generate(8, (_) => FocusNode());
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
    for (final focus in _focuses) {
      focus.dispose();
    }
    super.dispose();
  }

  int? _amount(String s, {bool allowNegative = false}) {
    final n = Money.tryParsePtBr(s);
    return n == null || (!allowNegative && n < 0) ? null : n;
  }

  void _save() {
    if (!(_key.currentState?.validate() ?? false)) {
      final invalidIndex = _name.text.trim().isEmpty
          ? 0
          : _category.text.trim().isEmpty
          ? 2
          : _amount(_invested.text) == null
          ? 5
          : _amount(_current.text) == null
          ? 6
          : 7;
      final target = _focuses[invalidIndex];
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
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            '${widget.data.funds.length} fundo(s) monitorado(s)',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _key,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _editing == null ? 'Novo fundo' : 'Editar fundo',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumns =
                            constraints.maxWidth >= 640 &&
                            MediaQuery.textScalerOf(context).scale(14) <= 19;
                        final fieldWidth = twoColumns
                            ? (constraints.maxWidth - AppSpacing.sm) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            SizedBox(
                              width: fieldWidth,
                              child: _field(_name, 'Nome', 0, required: true),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: _field(_account, 'Conta ou corretora', 1),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: _field(
                                _category,
                                'Categoria',
                                2,
                                required: true,
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: _field(_benchmark, 'Benchmark', 3),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: _field(_liquidity, 'Liquidez', 4),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: _money(
                                _invested,
                                'Valor aplicado',
                                5,
                                required: true,
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: _money(
                                _current,
                                'Valor atual',
                                6,
                                required: true,
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: _money(
                                _yield,
                                'Rendimento mensal',
                                7,
                                allowNegative: true,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
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
      ),
    ),
  );
  Widget _field(
    TextEditingController c,
    String label,
    int index, {
    bool required = false,
  }) => TextFormField(
    controller: c,
    focusNode: _focuses[index],
    textInputAction: index == 7 ? TextInputAction.done : TextInputAction.next,
    onFieldSubmitted: (_) =>
        index == 7 ? _save() : _focuses[index + 1].requestFocus(),
    decoration: InputDecoration(labelText: label),
    validator: required
        ? (v) => v == null || v.trim().isEmpty ? 'Informe $label' : null
        : null,
  );
  Widget _money(
    TextEditingController c,
    String label,
    int index, {
    bool required = false,
    bool allowNegative = false,
  }) => TextFormField(
    controller: c,
    focusNode: _focuses[index],
    textInputAction: index == 7 ? TextInputAction.done : TextInputAction.next,
    onFieldSubmitted: (_) =>
        index == 7 ? _save() : _focuses[index + 1].requestFocus(),
    decoration: InputDecoration(
      labelText: allowNegative ? 'Rendimento (R\$)' : '$label (R\$)',
      helperText: allowNegative ? 'Mensal; negativo para perdas' : null,
    ),
    keyboardType: TextInputType.numberWithOptions(
      decimal: true,
      signed: allowNegative,
    ),
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
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(child: Text(result >= 0 ? '+' : '−')),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    f.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              f.account.isEmpty ? f.category : f.account,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text('Valor atual'),
            ReadableValueText(
              value: Money.formatBr(f.currentCents),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text('Resultado'),
            ReadableValueText(
              value: Money.formatBr(result),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: result >= 0
                    ? Theme.of(context).extension<FinanceColors>()?.income
                    : Theme.of(context).extension<FinanceColors>()?.expense,
                fontWeight: FontWeight.w700,
              ),
            ),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () => _edit(f),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
                TextButton.icon(
                  onPressed: () => _remove(f),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remover'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
