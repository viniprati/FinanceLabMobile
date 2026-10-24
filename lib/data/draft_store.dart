import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Rascunho cifrado, separado pelo ID da conta.
abstract class DraftStore {
  Future<String?> read(String userId);
  Future<void> write(String userId, String value);
  Future<void> delete(String userId);
}

class SecureDraftStore implements DraftStore {
  const SecureDraftStore([this.storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage storage;

  String _key(String userId) => 'finance_draft_$userId';

  @override
  Future<String?> read(String userId) => storage.read(key: _key(userId));

  @override
  Future<void> write(String userId, String value) =>
      storage.write(key: _key(userId), value: value);

  @override
  Future<void> delete(String userId) => storage.delete(key: _key(userId));
}
