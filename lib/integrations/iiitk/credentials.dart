import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef CollegeLogin = ({String email, String password});

/// Where the college portal login lives. Device-only: never synced anywhere.
abstract class CredentialStore {
  Future<CollegeLogin?> read();
  Future<void> write(CollegeLogin login);
  Future<void> clear();
}

/// Android Keystore / iOS Keychain backed store.
class SecureCredentialStore implements CredentialStore {
  const SecureCredentialStore([this._storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage _storage;
  static const _email = 'iiitk_email';
  static const _password = 'iiitk_password';

  @override
  Future<CollegeLogin?> read() async {
    final e = await _storage.read(key: _email);
    final p = await _storage.read(key: _password);
    return e == null || p == null ? null : (email: e, password: p);
  }

  @override
  Future<void> write(CollegeLogin login) async {
    await _storage.write(key: _email, value: login.email.trim());
    await _storage.write(key: _password, value: login.password);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _email);
    await _storage.delete(key: _password);
  }
}

class MemoryCredentialStore implements CredentialStore {
  CollegeLogin? value;
  @override
  Future<CollegeLogin?> read() async => value;
  @override
  Future<void> write(CollegeLogin login) async => value = login;
  @override
  Future<void> clear() async => value = null;
}
