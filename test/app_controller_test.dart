import 'dart:async';

import 'package:financelab_mobile/app_controller.dart';
import 'package:financelab_mobile/data/api.dart';
import 'package:financelab_mobile/data/draft_store.dart';
import 'package:financelab_mobile/domain/demo_access.dart';
import 'package:financelab_mobile/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApi extends FinanceApi {
  _FakeApi() : super(Uri.parse('https://example.test'));

  final writes = <FinanceData>[];
  final firstWriteStarted = Completer<void>();
  final releaseFirstWrite = Completer<void>();
  bool failNextWrite = false;
  int loginCalls = 0;
  int failStatus = 500;
  FinanceData stored = const FinanceData();

  @override
  Future<AppUser> login(String email, String password, bool legal) async {
    loginCalls++;
    return const AppUser(
      id: 'test-user',
      name: 'Pessoa Teste',
      email: 'teste@example.test',
      role: 'user',
      plan: 'mensal',
      status: 'active',
    );
  }

  @override
  Future<FinanceData> loadData() async => stored;

  @override
  Future<void> saveData(FinanceData data) async {
    writes.add(data);
    if (writes.length == 1) {
      firstWriteStarted.complete();
      await releaseFirstWrite.future;
    }
    if (failNextWrite) {
      failNextWrite = false;
      throw ApiException(
        failStatus == 401 ? 'Sessão expirada' : 'Servidor indisponível',
        status: failStatus,
      );
    }
    stored = data;
  }
}

class _MemoryDraftStore implements DraftStore {
  final drafts = <String, String>{};
  @override
  Future<String?> read(String userId) async => drafts[userId];
  @override
  Future<void> write(String userId, String value) async {
    drafts[userId] = value;
  }

  @override
  Future<void> delete(String userId) async {
    drafts.remove(userId);
  }
}

void main() {
  test('modo demonstração usa dados fictícios sem criar gravação pendente', () {
    final controller = AppController(null);
    addTearDown(controller.dispose);

    controller.enterDemo();

    expect(controller.demo, isTrue);
    expect(controller.data.transactions, isNotEmpty);
    expect(controller.summary.incomeCents, greaterThan(0));
    expect(controller.hasUnsavedChanges, isFalse);
  });

  test('credenciais públicas de demo não acessam a API', () async {
    final api = _FakeApi();
    final controller = AppController(api, draftStore: _MemoryDraftStore());
    addTearDown(controller.dispose);

    await controller.login(
      DemoAccess.email.toUpperCase(),
      DemoAccess.password,
      false,
    );

    expect(controller.demo, isTrue);
    expect(controller.user?.id, 'demo');
    expect(controller.data.transactions, isNotEmpty);
    expect(api.loginCalls, 0);
    expect(api.writes, isEmpty);
  });

  test('sem API, credenciais comuns não entram na demonstração', () async {
    final controller = AppController(null);
    addTearDown(controller.dispose);

    await controller.login(DemoAccess.email, 'senha-incorreta', false);

    expect(controller.user, isNull);
    expect(controller.demo, isFalse);
    expect(controller.error, contains('URL HTTPS'));
  });

  test('serializa gravações e conserva a última edição', () async {
    final api = _FakeApi();
    final controller = AppController(api, draftStore: _MemoryDraftStore());
    addTearDown(controller.dispose);
    await controller.login('teste@example.test', 'senha', true);

    final first = const FinanceData(goals: Goals(monthlyBudgetCents: 10000));
    final second = const FinanceData(goals: Goals(monthlyBudgetCents: 20000));
    controller.updateData(first);
    await api.firstWriteStarted.future;
    controller.updateData(second);

    expect(api.writes, hasLength(1));
    final pending = controller.retrySave();
    api.releaseFirstWrite.complete();
    await pending;

    expect(api.writes, hasLength(2));
    expect(api.writes.last.goals.monthlyBudgetCents, 20000);
    expect(controller.hasUnsavedChanges, isFalse);
  });

  test('mantém edição após falha e permite tentar novamente', () async {
    final api = _FakeApi()..failNextWrite = true;
    final controller = AppController(api, draftStore: _MemoryDraftStore());
    addTearDown(controller.dispose);
    await controller.login('teste@example.test', 'senha', true);

    controller.updateData(
      const FinanceData(goals: Goals(emergencySavedCents: 5500)),
    );
    await api.firstWriteStarted.future;
    final pending = controller.retrySave();
    api.releaseFirstWrite.complete();
    await pending;

    expect(controller.hasUnsavedChanges, isTrue);
    expect(controller.saveError, contains('Servidor indisponível'));
    expect(controller.data.goals.emergencySavedCents, 5500);

    await controller.retrySave();
    expect(controller.hasUnsavedChanges, isFalse);
    expect(api.writes, hasLength(2));
  });

  test('recupera rascunho cifrado após reiniciar e permite salvar', () async {
    final api = _FakeApi()..failNextWrite = true;
    final store = _MemoryDraftStore();
    final first = AppController(api, draftStore: store);
    await first.login('teste@example.test', 'senha', true);
    first.updateData(
      const FinanceData(goals: Goals(emergencySavedCents: 5500)),
    );
    await api.firstWriteStarted.future;
    api.releaseFirstWrite.complete();
    await first.retrySave();
    expect(first.hasUnsavedChanges, isTrue);
    expect(store.drafts['test-user'], isNotNull);

    final restored = AppController(api, draftStore: store);
    addTearDown(first.dispose);
    addTearDown(restored.dispose);
    await restored.login('teste@example.test', 'senha', true);
    expect(restored.data.goals.emergencySavedCents, 5500);
    expect(restored.hasUnsavedChanges, isTrue);
    await restored.retrySave();
    expect(restored.hasUnsavedChanges, isFalse);
    expect(store.drafts, isEmpty);
  });

  test('não sobrescreve alteração feita em outro acesso', () async {
    final api = _FakeApi();
    final store = _MemoryDraftStore();
    final controller = AppController(api, draftStore: store);
    addTearDown(controller.dispose);
    await controller.login('teste@example.test', 'senha', true);
    api.stored = const FinanceData(goals: Goals(monthlyBudgetCents: 9000));
    controller.updateData(
      const FinanceData(goals: Goals(emergencySavedCents: 5500)),
    );
    await controller.retrySave();
    expect(api.writes, isEmpty);
    expect(controller.hasUnsavedChanges, isTrue);
    expect(controller.saveError, contains('outro acesso'));
    expect(store.drafts['test-user'], isNotNull);
  });

  test('401 conserva rascunho para novo login', () async {
    final api = _FakeApi()
      ..failNextWrite = true
      ..failStatus = 401;
    final store = _MemoryDraftStore();
    final controller = AppController(api, draftStore: store);
    addTearDown(controller.dispose);
    await controller.login('teste@example.test', 'senha', true);
    controller.updateData(
      const FinanceData(goals: Goals(emergencySavedCents: 7000)),
    );
    await api.firstWriteStarted.future;
    api.releaseFirstWrite.complete();
    await controller.retrySave();
    expect(controller.sessionExpired, isTrue);
    expect(store.drafts['test-user'], isNotNull);

    await controller.reloginPreservingDraft();
    expect(controller.user, isNull);
    await controller.login('teste@example.test', 'senha', true);
    expect(controller.data.goals.emergencySavedCents, 7000);
    expect(controller.hasUnsavedChanges, isTrue);
    await controller.retrySave();
    expect(controller.hasUnsavedChanges, isFalse);
  });
}
