import 'dart:async';
import 'dart:convert';

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
  bool loseNextResponse = false;
  int loginCalls = 0;
  int failStatus = 500;
  FinanceData stored = const FinanceData();
  int revision = 1;
  String get etag => '"rev-$revision"';

  void externalWrite(FinanceData next) {
    stored = next;
    revision++;
  }

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
  Future<void> logout() async {}

  @override
  Future<VersionedFinanceData> loadData() async =>
      VersionedFinanceData(data: stored, etag: etag);

  @override
  Future<String> saveData(FinanceData data, {required String ifMatch}) async {
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
    if (ifMatch != etag) {
      throw ApiException('Os dados mudaram em outro acesso.', status: 412);
    }
    stored = data;
    revision++;
    if (loseNextResponse) {
      loseNextResponse = false;
      throw ApiException('A API demorou a responder.');
    }
    return etag;
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

class _FailingDraftStore extends _MemoryDraftStore {
  bool failRead = false;
  bool failDelete = false;

  @override
  Future<String?> read(String userId) async {
    if (failRead) throw StateError('secure storage indisponível');
    return super.read(userId);
  }

  @override
  Future<void> delete(String userId) async {
    if (failDelete) throw StateError('secure storage indisponível');
    await super.delete(userId);
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
    api.externalWrite(
      const FinanceData(goals: Goals(monthlyBudgetCents: 9000)),
    );
    controller.updateData(
      const FinanceData(goals: Goals(emergencySavedCents: 5500)),
    );
    await controller.retrySave();
    expect(api.writes, isEmpty);
    expect(controller.hasUnsavedChanges, isTrue);
    expect(controller.saveError, contains('outro acesso'));
    expect(store.drafts['test-user'], isNotNull);
  });

  test('corrida entre leitura e PUT preserva as duas versões', () async {
    final api = _FakeApi();
    final controller = AppController(api, draftStore: _MemoryDraftStore());
    addTearDown(controller.dispose);
    await controller.login('teste@example.test', 'senha', true);

    controller.updateData(
      const FinanceData(goals: Goals(emergencySavedCents: 5500)),
    );
    await api.firstWriteStarted.future;
    api.externalWrite(
      const FinanceData(goals: Goals(monthlyBudgetCents: 9000)),
    );
    api.releaseFirstWrite.complete();
    await controller.retrySave();

    expect(controller.conflictDetected, isTrue);
    expect(controller.hasUnsavedChanges, isTrue);
    expect(controller.data.goals.emergencySavedCents, 5500);
    expect(api.stored.goals.monthlyBudgetCents, 9000);
    expect(api.stored.goals.emergencySavedCents, 0);
  });

  test('resposta perdida é reconciliada sem repetir o PUT', () async {
    final api = _FakeApi()..loseNextResponse = true;
    final store = _MemoryDraftStore();
    final controller = AppController(api, draftStore: store);
    addTearDown(controller.dispose);
    await controller.login('teste@example.test', 'senha', true);

    controller.updateData(
      const FinanceData(goals: Goals(emergencySavedCents: 5500)),
    );
    await api.firstWriteStarted.future;
    api.releaseFirstWrite.complete();
    await controller.retrySave();
    expect(controller.hasUnsavedChanges, isTrue);

    await controller.retrySave();
    expect(controller.hasUnsavedChanges, isFalse);
    expect(api.writes, hasLength(1));
    expect(store.drafts, isEmpty);
  });

  test(
    'resposta perdida com edição posterior envia só a versão mais nova',
    () async {
      final api = _FakeApi()..loseNextResponse = true;
      final controller = AppController(api, draftStore: _MemoryDraftStore());
      addTearDown(controller.dispose);
      await controller.login('teste@example.test', 'senha', true);

      controller.updateData(
        const FinanceData(goals: Goals(emergencySavedCents: 5500)),
      );
      await api.firstWriteStarted.future;
      controller.updateData(
        const FinanceData(goals: Goals(emergencySavedCents: 7000)),
      );
      api.releaseFirstWrite.complete();
      await controller.retrySave();
      expect(controller.hasUnsavedChanges, isTrue);

      await controller.retrySave();
      expect(controller.hasUnsavedChanges, isFalse);
      expect(api.writes, hasLength(2));
      expect(api.stored.goals.emergencySavedCents, 7000);
    },
  );

  test('rascunho ilegível bloqueia edição até descarte explícito', () async {
    final store = _MemoryDraftStore()..drafts['test-user'] = '{invalid';
    final api = _FakeApi();
    final controller = AppController(api, draftStore: store);
    addTearDown(controller.dispose);
    await controller.login('teste@example.test', 'senha', true);

    expect(controller.unreadableDraft, isTrue);
    controller.updateData(
      const FinanceData(goals: Goals(emergencySavedCents: 5500)),
    );
    expect(controller.data.goals.emergencySavedCents, 0);
    expect(store.drafts['test-user'], '{invalid');

    await controller.discardUnreadableDraft();
    expect(controller.unreadableDraft, isFalse);
    expect(store.drafts, isEmpty);
  });

  test('sair sem confirmação mantém rascunho ilegível', () async {
    final store = _MemoryDraftStore()..drafts['test-user'] = '{invalid';
    final controller = AppController(_FakeApi(), draftStore: store);
    addTearDown(controller.dispose);
    await controller.login('teste@example.test', 'senha', true);

    await controller.logout();
    expect(controller.user, isNotNull);
    expect(store.drafts['test-user'], '{invalid');

    await controller.logout(discardPendingDraft: true);
    expect(controller.user, isNull);
    expect(store.drafts, isEmpty);
  });

  test(
    'falha ao ler armazenamento mantém sessão e dados do servidor',
    () async {
      final store = _FailingDraftStore()..failRead = true;
      final api = _FakeApi()
        ..stored = const FinanceData(goals: Goals(monthlyBudgetCents: 9000));
      final controller = AppController(api, draftStore: store);
      addTearDown(controller.dispose);

      await controller.login('teste@example.test', 'senha', true);
      expect(controller.user?.id, 'test-user');
      expect(controller.data.goals.monthlyBudgetCents, 9000);
      expect(controller.unreadableDraft, isTrue);
      expect(controller.draftReadFailed, isTrue);
      expect(controller.hasUnsavedChanges, isFalse);
    },
  );

  test('falha ao limpar rascunho confirmado não bloqueia edição', () async {
    final api = _FakeApi();
    final store = _FailingDraftStore()
      ..failDelete = true
      ..drafts['test-user'] = jsonEncode({
        'base': jsonEncode(api.stored.toJson()),
        'data': api.stored.toJson(),
      });
    final controller = AppController(api, draftStore: store);
    addTearDown(controller.dispose);

    await controller.login('teste@example.test', 'senha', true);
    expect(controller.user, isNotNull);
    expect(controller.unreadableDraft, isFalse);
    expect(controller.draftCleanupFailed, isTrue);
    expect(controller.hasUnsavedChanges, isFalse);

    store.failDelete = false;
    await controller.retryDraftCleanup();
    expect(controller.draftCleanupFailed, isFalse);
    expect(store.drafts, isEmpty);
  });

  test(
    'falha ao apagar rascunho após PUT mantém sucesso e permite limpeza',
    () async {
      final api = _FakeApi();
      final store = _FailingDraftStore()..failDelete = true;
      final controller = AppController(api, draftStore: store);
      addTearDown(controller.dispose);
      await controller.login('teste@example.test', 'senha', true);

      controller.updateData(
        const FinanceData(goals: Goals(emergencySavedCents: 5500)),
      );
      await api.firstWriteStarted.future;
      final pending = controller.retrySave();
      api.releaseFirstWrite.complete();
      await pending;

      expect(controller.hasUnsavedChanges, isFalse);
      expect(controller.draftCleanupFailed, isTrue);
      expect(controller.saveError, contains('já estão no servidor'));
      expect(api.stored.goals.emergencySavedCents, 5500);
      expect(store.drafts['test-user'], isNotNull);

      store.failDelete = false;
      await controller.retryDraftCleanup();
      expect(controller.draftCleanupFailed, isFalse);
      expect(store.drafts, isEmpty);
    },
  );

  test('substituição remota exige a revisão vista na comparação', () async {
    final api = _FakeApi();
    final controller = AppController(api, draftStore: _MemoryDraftStore());
    addTearDown(controller.dispose);
    await controller.login('teste@example.test', 'senha', true);
    api.externalWrite(
      const FinanceData(goals: Goals(monthlyBudgetCents: 9000)),
    );
    controller.updateData(
      const FinanceData(goals: Goals(emergencySavedCents: 5500)),
    );
    await controller.retrySave();
    expect(controller.conflictDetected, isTrue);

    await controller.loadConflictServerData();
    final firstReview = controller.conflictReviewEtag!;
    api.externalWrite(
      const FinanceData(goals: Goals(monthlyBudgetCents: 11000)),
    );
    await expectLater(
      controller.replaceRemoteWithLocal(firstReview),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 412)),
    );
    expect(api.stored.goals.monthlyBudgetCents, 11000);
    expect(controller.data.goals.emergencySavedCents, 5500);

    await controller.loadConflictServerData();
    final accepted = controller.replaceRemoteWithLocal(
      controller.conflictReviewEtag!,
    );
    await api.firstWriteStarted.future;
    api.releaseFirstWrite.complete();
    await accepted;
    expect(controller.hasUnsavedChanges, isFalse);
    expect(api.stored.goals.emergencySavedCents, 5500);
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
