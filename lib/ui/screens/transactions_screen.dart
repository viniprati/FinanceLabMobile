import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models.dart';
import '../../domain/summary.dart';
import '../../domain/money.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({
    super.key,
    required this.data,
    this.summary,
    required this.onDataChanged,
    this.monthKey,
    this.editingBlocked = false,
  });
  final FinanceData data;
  final FinanceSummary? summary;
  final ValueChanged<FinanceData> onDataChanged;
  final String? monthKey;
  final bool editingBlocked;
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final keyForm = GlobalKey<FormState>(),
      category = TextEditingController(),
      description = TextEditingController(),
      subcategory = TextEditingController(),
      amount = TextEditingController();
  final categoryFocus = FocusNode();
  final subcategoryFocus = FocusNode();
  final descriptionFocus = FocusNode();
  final amountFocus = FocusNode();
  String kind = 'expense';
  DateTime date = DateTime.now();
  final search = TextEditingController();
  String filterKind = 'all';
  String filterCategory = 'all';
  bool showForm = false;
  @override
  void dispose() {
    category.dispose();
    description.dispose();
    subcategory.dispose();
    amount.dispose();
    categoryFocus.dispose();
    subcategoryFocus.dispose();
    descriptionFocus.dispose();
    amountFocus.dispose();
    search.dispose();
    super.dispose();
  }

  int? cents(String v) {
    final value = Money.tryParsePtBr(v);
    return value != null && value > 0 ? value : null;
  }

  void add() {
    if (widget.editingBlocked) return;
    if (!(keyForm.currentState?.validate() ?? false)) {
      FocusNode? target;
      if (category.text.trim().isEmpty) {
        target = categoryFocus;
      } else if (cents(amount.text) == null) {
        target = amountFocus;
      }
      target?.requestFocus();
      if (target != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || target?.context == null) return;
          Scrollable.ensureVisible(
            target!.context!,
            alignment: .2,
            duration: const Duration(milliseconds: 200),
          );
        });
      }
      return;
    }
    final t = Transaction(
      id: const Uuid().v4(),
      type: kind == 'income' ? 'income' : 'expense',
      kind: kind,
      date: date.toIso8601String().substring(0, 10),
      category: category.text.trim(),
      subcategory: subcategory.text.trim(),
      description: description.text.trim().isEmpty
          ? category.text.trim()
          : description.text.trim(),
      amountCents: cents(amount.text)!,
    );
    widget.onDataChanged(
      widget.data.copyWith(transactions: [t, ...widget.data.transactions]),
    );
    category.clear();
    description.clear();
    subcategory.clear();
    amount.clear();
    setState(() => showForm = false);
  }

  Future<void> remove(Transaction t) async {
    if (widget.editingBlocked) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remover lançamento?'),
        content: Text(t.description),
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
    if (ok == true && !widget.editingBlocked) {
      widget.onDataChanged(
        widget.data.copyWith(
          transactions: widget.data.transactions
              .where((x) => x.id != t.id)
              .toList(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        widget.data.transactions
            .where(
              (t) =>
                  widget.monthKey == null ||
                  t.date.startsWith(widget.monthKey!),
            )
            .map((t) => t.category)
            .where((value) => value.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final effectiveCategory = categories.contains(filterCategory)
        ? filterCategory
        : 'all';
    final filtered = widget.data.transactions.where((t) {
      final period =
          widget.monthKey == null || t.date.startsWith(widget.monthKey!);
      final needle = search.text.trim().toLowerCase();
      final matchesText =
          needle.isEmpty ||
          [
            t.category,
            t.subcategory,
            t.description,
            t.date,
            t.type,
            t.kind,
          ].any((value) => value.toLowerCase().contains(needle));
      return period &&
          matchesText &&
          (filterKind == 'all' || t.kind == filterKind) &&
          (effectiveCategory == 'all' || t.category == effectiveCategory);
    }).toList();
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: widget.editingBlocked
                    ? null
                    : () => setState(() => showForm = !showForm),
                icon: Icon(showForm ? Icons.close : Icons.add),
                label: Text(showForm ? 'Fechar' : 'Novo lançamento'),
              ),
            ),
            const SizedBox(height: 12),
            if (showForm) _formCard(),
            if (showForm) const SizedBox(height: 16),
            TextField(
              controller: search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Buscar',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns =
                    constraints.maxWidth >=
                    MediaQuery.textScalerOf(context).scale(520).clamp(520, 900);
                final filterWidth = twoColumns
                    ? (constraints.maxWidth - AppSpacing.sm) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: filterWidth,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: filterKind,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('Todos os tipos'),
                          ),
                          DropdownMenuItem(
                            value: 'income',
                            child: Text('Receitas'),
                          ),
                          DropdownMenuItem(
                            value: 'expense',
                            child: Text('Despesas'),
                          ),
                          DropdownMenuItem(
                            value: 'contribution',
                            child: Text('Aportes'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => filterKind = value ?? 'all'),
                      ),
                    ),
                    SizedBox(
                      width: filterWidth,
                      child: PopupMenuButton<String>(
                        tooltip: 'Filtrar por categoria',
                        onSelected: (value) =>
                            setState(() => filterCategory = value),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'all',
                            child: Text('Todas as categorias'),
                          ),
                          for (final value in categories)
                            PopupMenuItem(value: value, child: Text(value)),
                        ],
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                          child: Text(
                            effectiveCategory == 'all'
                                ? 'Todas as categorias'
                                : effectiveCategory,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${filtered.length} lançamento(s) encontrado(s)',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nenhum lançamento neste período.'),
              ),
            ...filtered.map((t) => _transactionCard(t)),
          ],
        ),
      ),
    );
  }

  Widget _formCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: keyForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: kind,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: const [
                DropdownMenuItem(value: 'expense', child: Text('Despesa')),
                DropdownMenuItem(value: 'income', child: Text('Receita')),
                DropdownMenuItem(value: 'contribution', child: Text('Aporte')),
              ],
              onChanged: (v) => setState(() => kind = v ?? 'expense'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: category,
              focusNode: categoryFocus,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => subcategoryFocus.requestFocus(),
              decoration: const InputDecoration(labelText: 'Categoria'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Informe a categoria' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: subcategory,
              focusNode: subcategoryFocus,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => descriptionFocus.requestFocus(),
              decoration: const InputDecoration(
                labelText: 'Subcategoria',
                helperText: 'Opcional',
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data'),
              subtitle: Text(
                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (selected != null) setState(() => date = selected);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: description,
              focusNode: descriptionFocus,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => amountFocus.requestFocus(),
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: amount,
              focusNode: amountFocus,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => add(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Valor (R\$)'),
              validator: (v) =>
                  cents(v ?? '') == null ? 'Informe um valor válido' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: widget.editingBlocked ? null : add,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _transactionCard(Transaction transaction) => Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  transaction.description,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Remover',
                onPressed: widget.editingBlocked
                    ? null
                    : () => remove(transaction),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          Text(
            '${transaction.category} · ${transaction.date}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(switch (transaction.kind) {
                  'income' => 'Receita',
                  'contribution' => 'Aporte',
                  'expense' => 'Despesa',
                  _ => 'Lançamento',
                }, style: Theme.of(context).textTheme.labelSmall),
                ReadableValueText(
                  value: Money.formatBr(transaction.amountCents),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: switch (transaction.kind) {
                      'income' => Theme.of(
                        context,
                      ).extension<FinanceColors>()?.income,
                      'contribution' => Theme.of(
                        context,
                      ).extension<FinanceColors>()?.contribution,
                      _ => Theme.of(
                        context,
                      ).extension<FinanceColors>()?.expense,
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
