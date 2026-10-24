import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:financelab_mobile/data/api.dart';
import 'package:financelab_mobile/domain/models.dart';

class Store implements SessionStore {
  String? value;
  @override
  Future<String?> read() => Future.value(value);
  @override
  Future<void> write(String v) async => value = v;
  @override
  Future<void> delete() async => value = null;
}

void main() {
  test('login captures fp_session cookie and restore sends it', () async {
    final store = Store();
    var cookie = '';
    final client = MockClient((r) async {
      cookie = r.headers['cookie'] ?? '';
      if (r.url.path.endsWith('login')) {
        return http.Response(
          '{"user":{"id":"1"}}',
          200,
          headers: {'set-cookie': 'fp_session=opaque; Path=/; HttpOnly'},
        );
      }
      return http.Response('{"user":{"id":"1"}}', 200);
    });
    final api = FinanceApi(
      Uri.parse('https://example.com'),
      client: client,
      sessionStore: store,
    );
    await api.login('a', 'b', true);
    expect(store.value, 'opaque');
    await api.restoreSession();
    expect(cookie, 'fp_session=opaque');
  });
  test('401 clears session', () async {
    final store = Store()..value = 'old';
    final api = FinanceApi(
      Uri.parse('https://example.com'),
      client: MockClient((_) async => http.Response('{"error":"no"}', 401)),
      sessionStore: store,
    );
    expect(await api.restoreSession(), isNull);
    expect(store.value, isNull);
  });
  test('login sem cookie de sessão é rejeitado', () async {
    final store = Store();
    final api = FinanceApi(
      Uri.parse('https://example.com'),
      client: MockClient(
        (_) async => http.Response('{"user":{"id":"1"}}', 200),
      ),
      sessionStore: store,
    );
    await expectLater(api.login('a', 'b', true), throwsA(isA<ApiException>()));
    expect(store.value, isNull);
  });
  test('exportação e eliminação usam sessão autenticada', () async {
    final paths = <String>[];
    final store = Store()..value = 'session-1';
    final api = FinanceApi(
      Uri.parse('https://example.com'),
      client: MockClient((request) async {
        expect(request.headers['cookie'], 'fp_session=session-1');
        paths.add('${request.method} ${request.url.path}');
        if (request.url.path.endsWith('/export')) {
          return http.Response('{"financeData":{"transactions":[]}}', 200);
        }
        expect(request.body, contains('correção'));
        return http.Response('{"ok":true,"requestId":"r1"}', 202);
      }),
      sessionStore: store,
    );
    expect((await api.exportPersonalData())['financeData'], isA<Map>());
    expect((await api.requestErasure(reason: 'correção'))['requestId'], 'r1');
    expect(paths, ['GET /api/me/export', 'POST /api/me/erasure']);
  });
  test('resposta financeira malformada falha sem valores zerados', () async {
    final api = FinanceApi(
      Uri.parse('https://example.com'),
      client: MockClient(
        (_) async => http.Response(
          '{"transactions":[{"id":"x","type":"expense",'
          '"kind":"expense","date":"2026-10-01",'
          '"category":"Casa","description":"Conta",'
          '"amount":"indisponível"}],"funds":[],"budgets":[],'
          '"goals":{"monthlyBudget":0,"emergencyFund":0,'
          '"emergencySaved":0}}',
          200,
          headers: {'etag': '"rev-1"'},
        ),
      ),
      sessionStore: Store()..value = 'session-1',
    );
    await expectLater(
      api.loadData(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          contains('dados financeiros inválidos'),
        ),
      ),
    );
  });

  test('leitura recebe ETag e gravação usa If-Match', () async {
    final requests = <http.Request>[];
    final api = FinanceApi(
      Uri.parse('https://example.com'),
      client: MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET') {
          return http.Response(
            '{"transactions":[],"funds":[],"budgets":[],"goals":'
            '{"monthlyBudget":0,"emergencyFund":0,"emergencySaved":0}}',
            200,
            headers: {'etag': '"rev-1"'},
          );
        }
        return http.Response('{"ok":true}', 200, headers: {'etag': '"rev-2"'});
      }),
      sessionStore: Store()..value = 'session-1',
    );

    final loaded = await api.loadData();
    expect(loaded.etag, '"rev-1"');
    final savedEtag = await api.saveData(loaded.data, ifMatch: loaded.etag);
    expect(savedEtag, '"rev-2"');
    expect(requests.last.headers['if-match'], '"rev-1"');
  });

  test('revisão obsoleta retorna 412 sem perder a sessão', () async {
    final store = Store()..value = 'session-1';
    final api = FinanceApi(
      Uri.parse('https://example.com'),
      client: MockClient(
        (_) async => http.Response('{"error":"Dados alterados."}', 412),
      ),
      sessionStore: store,
    );
    await expectLater(
      api.saveData(const FinanceData(), ifMatch: '"rev-1"'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 412)),
    );
    expect(store.value, 'session-1');
  });

  test('API sem ETag é incompatível e não permite gravação insegura', () async {
    final api = FinanceApi(
      Uri.parse('https://example.com'),
      client: MockClient(
        (_) async => http.Response(
          '{"transactions":[],"funds":[],"budgets":[],"goals":'
          '{"monthlyBudget":0,"emergencyFund":0,"emergencySaved":0}}',
          200,
        ),
      ),
      sessionStore: Store()..value = 'session-1',
    );
    await expectLater(
      api.loadData(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('precisa ser atualizada'),
        ),
      ),
    );
  });
}
