import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'data/api.dart';
import 'data/draft_store.dart';
import 'domain/demo_access.dart';
import 'domain/models.dart';
import 'domain/summary.dart';

/// Estado da sessão e dos dados financeiros apresentado pelas telas.
///
/// O servidor salva o documento financeiro inteiro. As gravações são
/// serializadas para que uma resposta antiga não sobrescreva uma edição nova.
class AppController extends ChangeNotifier {
  AppController(this._api, {DraftStore? draftStore})
    : _draftStore = draftStore ?? const SecureDraftStore();

  final FinanceApi? _api;
  final DraftStore _draftStore;
  AppUser? user;
  FinanceData data = const FinanceData();
  Map<String, dynamic>? adminOverview;
  String? error;
  String? saveError;
  bool initializing = true;
  bool busy = false;
  bool demo = false;
  bool saving = false;
  bool sessionExpired = false;
  String selectedMonth = _monthKey(DateTime.now());

  int _pendingRevision = 0;
  int _savedRevision = 0;
  Future<void>? _saveTask;
  Future<void> _draftTask = Future<void>.value();
  String? _serverFingerprint;

  bool get hasUnsavedChanges => !demo && _pendingRevision > _savedRevision;
  FinanceSummary get summary => FinanceSummary.fromData(data, selectedMonth);

  List<String> get availableMonths {
    final keys = <String>{_monthKey(DateTime.now()), selectedMonth};
    for (final transaction in data.transactions) {
      if (RegExp(r'^\d{4}-\d{2}').hasMatch(transaction.date)) {
        keys.add(transaction.date.substring(0, 7));
      }
    }
    return keys.toList()..sort((a, b) => b.compareTo(a));
  }

  Future<void> initialize() async {
    if (_api == null) {
      initializing = false;
      notifyListeners();
      return;
    }
    try {
      user = await _api.restoreSession();
      if (user != null) await _loadForUser();
    } catch (exception) {
      user = null;
      error = _friendlyError(exception);
    } finally {
      initializing = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password, bool acceptedLegal) async {
    if (busy) return;
    if (DemoAccess.matches(email, password)) {
      enterDemo();
      return;
    }
    if (_api == null) {
      error = 'Configure uma URL HTTPS da API para entrar com sua conta.';
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      user = await _api.login(email, password, acceptedLegal);
      demo = false;
      sessionExpired = false;
      await _loadForUser();
    } catch (exception) {
      user = null;
      error = _friendlyError(exception);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _loadForUser() async {
    if (user?.role == 'admin') {
      adminOverview = await _api!.loadAdminOverview();
      data = const FinanceData();
      _serverFingerprint = null;
    } else {
      final remote = await _api!.loadData();
      _serverFingerprint = _fingerprint(remote);
      data = remote;
      adminOverview = null;
    }
    _pendingRevision = 0;
    _savedRevision = 0;
    saveError = null;
    sessionExpired = false;
    if (user?.role != 'admin') {
      final draft = await _draftStore.read(user!.id);
      if (draft != null) {
        try {
          final payload = jsonDecode(draft) as Map<String, dynamic>;
          final recovered = FinanceData.fromJson(
            Map<String, dynamic>.from(payload['data'] as Map),
          );
          if (_fingerprint(recovered) == _serverFingerprint) {
            await _draftStore.delete(user!.id);
          } else {
            data = recovered;
            _pendingRevision = 1;
            saveError = payload['base'] == _serverFingerprint
                ? 'Rascunho local recuperado. Toque em Tentar novamente para salvar.'
                : 'Os dados do servidor mudaram desde este rascunho. '
                      'Exporte uma cópia local antes de decidir como resolver.';
            _serverFingerprint = payload['base']?.toString();
          }
        } catch (_) {
          saveError =
              'Há um rascunho local ilegível no aparelho. '
              'Nenhum dado foi sobrescrito.';
        }
      }
    }
  }

  void enterDemo() {
    user = const AppUser(
      id: 'demo',
      name: 'Conta de demonstração',
      email: 'Dados fictícios',
      role: 'user',
      plan: 'demo',
      status: 'active',
    );
    data = _makeDemoData(DateTime.now());
    selectedMonth = _monthKey(DateTime.now());
    demo = true;
    sessionExpired = false;
    error = null;
    saveError = null;
    notifyListeners();
  }

  void selectMonth(String value) {
    if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(value)) return;
    selectedMonth = value;
    notifyListeners();
  }

  void updateData(FinanceData next) {
    if (user == null || user?.role == 'admin') return;
    data = next;
    if (!demo) {
      _pendingRevision++;
      saveError = null;
      _queueDraftWrite(next);
      _saveTask ??= _persistChanges();
    }
    notifyListeners();
  }

  Future<void> retrySave() async {
    if (demo || !hasUnsavedChanges || _api == null) return;
    saveError = null;
    notifyListeners();
    _saveTask ??= _persistChanges();
    await _saveTask;
  }

  Future<void> _persistChanges() async {
    saving = true;
    notifyListeners();
    try {
      while (_savedRevision < _pendingRevision) {
        final revision = _pendingRevision;
        final snapshot = data;
        try {
          // Atualiza a base após cada PUT confirmado antes de persistir a
          // próxima revisão. Assim, um reinício não gera falso conflito.
          _queueDraftWrite(snapshot);
          await _draftTask;
          final remote = await _api!.loadData();
          if (_serverFingerprint != _fingerprint(remote)) {
            throw ApiException(
              'Os dados mudaram em outro acesso. Exporte o rascunho local '
              'antes de recarregar os dados do servidor.',
              status: 409,
            );
          }
          await _api.saveData(snapshot);
          _serverFingerprint = _fingerprint(snapshot);
          _savedRevision = revision;
          saveError = null;
          if (_pendingRevision == revision) {
            _draftTask = _draftTask.then((_) => _draftStore.delete(user!.id));
            await _draftTask;
          }
        } catch (exception) {
          saveError = _friendlyError(exception);
          sessionExpired = exception is ApiException && exception.status == 401;
          break;
        }
        notifyListeners();
      }
    } finally {
      saving = false;
      _saveTask = null;
      notifyListeners();
    }
  }

  void _queueDraftWrite(FinanceData snapshot) {
    final userId = user!.id;
    final payload = jsonEncode({
      'base': _serverFingerprint,
      'data': snapshot.toJson(),
    });
    _draftTask = _draftTask
        .catchError((Object _) {})
        .then((_) => _draftStore.write(userId, payload));
  }

  Future<Map<String, dynamic>> exportPersonalData() async {
    if (_api == null || demo || user == null) {
      throw ApiException('Entre em sua conta para exportar dados pessoais.');
    }
    if (hasUnsavedChanges) {
      throw ApiException('Salve as alterações pendentes antes de exportar.');
    }
    return _api.exportPersonalData();
  }

  Map<String, dynamic> exportLocalFinanceData() => data.toJson();

  Future<Map<String, dynamic>> requestErasure({String? reason}) async {
    if (_api == null || demo || user == null) {
      throw ApiException('Entre em sua conta para solicitar eliminação.');
    }
    return _api.requestErasure(reason: reason);
  }

  Future<void> importFinanceDataJson(String source) async {
    final imported = FinanceData.fromImportJson(source);
    updateData(imported);
  }

  Future<void> discardPendingChanges() async {
    if (_api == null || demo || user == null || !hasUnsavedChanges) return;
    if (_saveTask != null) await _saveTask;
    final remote = await _api.loadData();
    await _draftTask;
    await _draftStore.delete(user!.id);
    data = remote;
    _serverFingerprint = _fingerprint(remote);
    _pendingRevision = 0;
    _savedRevision = 0;
    saveError = null;
    error = null;
    notifyListeners();
  }

  Future<void> reloginPreservingDraft() async {
    if (_saveTask != null) await _saveTask;
    await _draftTask;
    user = null;
    data = const FinanceData();
    adminOverview = null;
    demo = false;
    sessionExpired = false;
    _pendingRevision = 0;
    _savedRevision = 0;
    error = 'Sua sessão expirou. Entre novamente para recuperar o rascunho.';
    saveError = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_api == null || demo || user == null) return;
    if (hasUnsavedChanges) {
      error = 'Salve as alterações pendentes antes de atualizar.';
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _loadForUser();
    } catch (exception) {
      error = _friendlyError(exception);
      if (exception is ApiException && exception.status == 401) {
        user = null;
        data = const FinanceData();
      }
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (_saveTask != null) await _saveTask;
    try {
      await _draftTask;
      if (!demo && user != null) await _draftStore.delete(user!.id);
    } catch (exception) {
      error =
          'Não foi possível limpar o rascunho local: '
          '${_friendlyError(exception)}';
      notifyListeners();
      return;
    }
    try {
      if (!demo) await _api?.logout();
    } catch (_) {
      // A sessão local é apagada pela API mesmo quando o servidor não responde.
    } finally {
      user = null;
      data = const FinanceData();
      adminOverview = null;
      demo = false;
      sessionExpired = false;
      busy = false;
      error = null;
      saveError = null;
      _pendingRevision = 0;
      _savedRevision = 0;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _api?.client.close();
    super.dispose();
  }
}

String _fingerprint(FinanceData data) => jsonEncode(data.toJson());

String _friendlyError(Object exception) {
  if (exception is ApiException) return exception.message;
  if (exception is FormatException) {
    return 'A API ou o arquivo contém dados financeiros inválidos.';
  }
  return 'Não foi possível conectar. Verifique sua internet e tente novamente.';
}

String _monthKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

String _dateKey(DateTime date) =>
    '${_monthKey(date)}-${date.day.toString().padLeft(2, '0')}';

FinanceData _makeDemoData(DateTime now) {
  final month = DateTime(now.year, now.month);
  final previous = DateTime(now.year, now.month - 1);
  return FinanceData.fromJson({
    'transactions': [
      {
        'id': 'demo-1',
        'type': 'income',
        'kind': 'income',
        'date': _dateKey(month.add(const Duration(days: 4))),
        'category': 'Salário',
        'subcategory': '',
        'description': 'Receita mensal',
        'amount': 6500.00,
      },
      {
        'id': 'demo-2',
        'type': 'expense',
        'kind': 'expense',
        'date': _dateKey(month.add(const Duration(days: 6))),
        'category': 'Moradia',
        'subcategory': 'Aluguel',
        'description': 'Aluguel',
        'amount': 1800.00,
      },
      {
        'id': 'demo-3',
        'type': 'expense',
        'kind': 'expense',
        'date': _dateKey(month.add(const Duration(days: 9))),
        'category': 'Alimentação',
        'subcategory': 'Mercado',
        'description': 'Compras do mês',
        'amount': 680.45,
      },
      {
        'id': 'demo-4',
        'type': 'expense',
        'kind': 'contribution',
        'date': _dateKey(month.add(const Duration(days: 11))),
        'category': 'Investimento',
        'subcategory': '',
        'description': 'Aporte mensal',
        'amount': 950.00,
      },
      {
        'id': 'demo-5',
        'type': 'expense',
        'kind': 'expense',
        'date': _dateKey(previous.add(const Duration(days: 12))),
        'category': 'Transporte',
        'subcategory': '',
        'description': 'Transporte',
        'amount': 310.00,
      },
    ],
    'funds': [
      {
        'id': 'demo-fund',
        'name': 'Reserva de exemplo',
        'account': 'Banco fictício',
        'category': 'Renda fixa',
        'benchmark': 'CDI',
        'liquidity': 'D+0',
        'invested': 12000.00,
        'current': 12580.90,
        'monthlyYield': 98.25,
      },
    ],
    'budgets': [
      {'id': 'demo-budget-1', 'category': 'Moradia', 'monthlyLimit': 2200.00},
      {
        'id': 'demo-budget-2',
        'category': 'Alimentação',
        'monthlyLimit': 1000.00,
      },
    ],
    'goals': {
      'monthlyBudget': 4000.00,
      'emergencyFund': 18000.00,
      'emergencySaved': 7500.00,
    },
  });
}
