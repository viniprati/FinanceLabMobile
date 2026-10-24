import 'dart:convert';

/// Largest amount that can safely cross the current JSON-number API contract.
/// A future API should exchange cents as integers/strings.
const maxMoneyCents = 10000000000000;

int _cents(Object? value, {required String field, bool allowNegative = false}) {
  final text = switch (value) {
    int value => '$value',
    double value when value.isFinite => value.toString(),
    String value => value.trim(),
    _ => '',
  };
  final match = RegExp(r'^(-?)(\d+)(?:\.(\d{1,2}))?$').firstMatch(text);
  if (match == null) {
    throw FormatException('Valor monetário inválido em $field.');
  }
  final whole = int.tryParse(match.group(2)!);
  if (whole == null) {
    throw FormatException('Valor monetário inválido em $field.');
  }
  final fraction = (match.group(3) ?? '').padRight(2, '0');
  final cents = whole * 100 + (fraction.isEmpty ? 0 : int.parse(fraction));
  final signed = match.group(1) == '-' ? -cents : cents;
  if ((!allowNegative && signed < 0) || signed.abs() > maxMoneyCents) {
    throw FormatException('Valor monetário fora do limite em $field.');
  }
  return signed;
}

double _real(int cents, {required String field}) {
  if (cents.abs() > maxMoneyCents) {
    throw ArgumentError.value(cents, field, 'Valor monetário fora do limite.');
  }
  return cents / 100;
}

String _requiredText(Object? value, String field) {
  final text = value is String ? value.trim() : '';
  if (text.isEmpty) throw FormatException('Campo obrigatório ausente: $field.');
  return text;
}

String _optionalText(Object? value, {String fallback = ''}) =>
    value is String ? value.trim() : fallback;

String _calendarDate(Object? value, String field) {
  final date = _requiredText(value, field);
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(date);
  if (match == null) throw FormatException('Data inválida em $field.');
  final parsed = DateTime.tryParse(date);
  if (parsed == null ||
      parsed.year != int.parse(match.group(1)!) ||
      parsed.month != int.parse(match.group(2)!) ||
      parsed.day != int.parse(match.group(3)!)) {
    throw FormatException('Data inválida em $field.');
  }
  return date;
}

Map<String, dynamic> _record(Object? value, String field) {
  if (value is! Map) throw FormatException('Objeto inválido em $field.');
  return Map<String, dynamic>.from(value);
}

List<dynamic> _list(Object? value, String field) {
  if (value is! List) throw FormatException('Lista inválida em $field.');
  return value;
}

class Transaction {
  final String id, type, kind, date, category, subcategory, description;
  final int amountCents;
  const Transaction({
    required this.id,
    required this.type,
    required this.kind,
    required this.date,
    required this.category,
    required this.subcategory,
    required this.description,
    required this.amountCents,
  });
  factory Transaction.fromJson(Map<String, dynamic> j) {
    final kind = _requiredText(j['kind'], 'transactions.kind');
    final type = _requiredText(j['type'], 'transactions.type');
    if (!const {'income', 'expense', 'contribution'}.contains(kind) ||
        !const {'income', 'expense'}.contains(type) ||
        (kind == 'income' && type != 'income') ||
        (kind != 'income' && type != 'expense')) {
      throw const FormatException('Tipo de lançamento inválido.');
    }
    return Transaction(
      id: _requiredText(j['id'], 'transactions.id'),
      type: type,
      kind: kind,
      date: _calendarDate(j['date'], 'transactions.date'),
      category: _requiredText(j['category'], 'transactions.category'),
      subcategory: _optionalText(j['subcategory']),
      description: _requiredText(j['description'], 'transactions.description'),
      amountCents: _cents(j['amount'], field: 'transactions.amount'),
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'kind': kind,
    'date': date,
    'category': category,
    'subcategory': subcategory,
    'description': description,
    'amount': _real(amountCents, field: 'transactions.amount'),
  };
}

class Fund {
  final String id, name, account, category, benchmark, liquidity;
  final int investedCents, currentCents, monthlyYieldCents;
  const Fund({
    required this.id,
    required this.name,
    required this.account,
    required this.category,
    required this.benchmark,
    required this.liquidity,
    required this.investedCents,
    required this.currentCents,
    required this.monthlyYieldCents,
  });
  factory Fund.fromJson(Map<String, dynamic> j) => Fund(
    id: _requiredText(j['id'], 'funds.id'),
    name: _requiredText(j['name'], 'funds.name'),
    account: _optionalText(j['account']),
    category: _requiredText(j['category'], 'funds.category'),
    benchmark: _optionalText(j['benchmark']),
    liquidity: _optionalText(j['liquidity']),
    investedCents: _cents(j['invested'], field: 'funds.invested'),
    currentCents: _cents(j['current'], field: 'funds.current'),
    monthlyYieldCents: _cents(
      j['monthlyYield'],
      field: 'funds.monthlyYield',
      allowNegative: true,
    ),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'account': account,
    'category': category,
    'benchmark': benchmark,
    'liquidity': liquidity,
    'invested': _real(investedCents, field: 'funds.invested'),
    'current': _real(currentCents, field: 'funds.current'),
    'monthlyYield': _real(monthlyYieldCents, field: 'funds.monthlyYield'),
  };
}

class Budget {
  final String id, category;
  final int monthlyLimitCents;
  const Budget({
    required this.id,
    required this.category,
    required this.monthlyLimitCents,
  });
  factory Budget.fromJson(Map<String, dynamic> j) => Budget(
    id: _requiredText(j['id'], 'budgets.id'),
    category: _requiredText(j['category'], 'budgets.category'),
    monthlyLimitCents: _cents(j['monthlyLimit'], field: 'budgets.monthlyLimit'),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'monthlyLimit': _real(monthlyLimitCents, field: 'budgets.monthlyLimit'),
  };
}

class Goals {
  final int monthlyBudgetCents, emergencyFundCents, emergencySavedCents;
  const Goals({
    this.monthlyBudgetCents = 0,
    this.emergencyFundCents = 0,
    this.emergencySavedCents = 0,
  });
  factory Goals.fromJson(Map<String, dynamic> j) => Goals(
    monthlyBudgetCents: _cents(
      j['monthlyBudget'],
      field: 'goals.monthlyBudget',
    ),
    emergencyFundCents: _cents(
      j['emergencyFund'],
      field: 'goals.emergencyFund',
    ),
    emergencySavedCents: _cents(
      j['emergencySaved'],
      field: 'goals.emergencySaved',
    ),
  );
  Map<String, dynamic> toJson() => {
    'monthlyBudget': _real(monthlyBudgetCents, field: 'goals.monthlyBudget'),
    'emergencyFund': _real(emergencyFundCents, field: 'goals.emergencyFund'),
    'emergencySaved': _real(emergencySavedCents, field: 'goals.emergencySaved'),
  };
}

class FinanceData {
  final List<Transaction> transactions;
  final List<Fund> funds;
  final List<Budget> budgets;
  final Goals goals;
  const FinanceData({
    this.transactions = const [],
    this.funds = const [],
    this.budgets = const [],
    this.goals = const Goals(),
  });
  factory FinanceData.fromJson(Map<String, dynamic> j) {
    final transactions = _list(j['transactions'], 'transactions')
        .map((x) => Transaction.fromJson(_record(x, 'transactions')))
        .toList(growable: false);
    final funds = _list(
      j['funds'],
      'funds',
    ).map((x) => Fund.fromJson(_record(x, 'funds'))).toList(growable: false);
    final budgets = _list(j['budgets'], 'budgets')
        .map((x) => Budget.fromJson(_record(x, 'budgets')))
        .toList(growable: false);
    _ensureUniqueIds(transactions.map((item) => item.id), 'transactions.id');
    _ensureUniqueIds(funds.map((item) => item.id), 'funds.id');
    _ensureUniqueIds(budgets.map((item) => item.id), 'budgets.id');
    return FinanceData(
      transactions: transactions,
      funds: funds,
      budgets: budgets,
      goals: Goals.fromJson(_record(j['goals'], 'goals')),
    );
  }

  factory FinanceData.fromImportJson(String source) {
    try {
      final root = _record(jsonDecode(source), 'arquivo');
      final data = root['financeData'] ?? root;
      return FinanceData.fromJson(_record(data, 'financeData'));
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException('Arquivo JSON financeiro inválido.');
    }
  }

  Map<String, dynamic> toJson() => {
    'transactions': transactions.map((x) => x.toJson()).toList(),
    'funds': funds.map((x) => x.toJson()).toList(),
    'budgets': budgets.map((x) => x.toJson()).toList(),
    'goals': goals.toJson(),
  };
  FinanceData copyWith({
    List<Transaction>? transactions,
    List<Fund>? funds,
    List<Budget>? budgets,
    Goals? goals,
  }) => FinanceData(
    transactions: transactions ?? this.transactions,
    funds: funds ?? this.funds,
    budgets: budgets ?? this.budgets,
    goals: goals ?? this.goals,
  );
}

void _ensureUniqueIds(Iterable<String> ids, String field) {
  final seen = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) {
      throw FormatException('ID duplicado em $field.');
    }
  }
}
