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
  const SecureCredentialStore({
    this.prefix = 'iiitk',
    this.storage = const FlutterSecureStorage(),
  });

  /// `iiitk` for the attendance portal, `lms` for Moodle.
  final String prefix;
  final FlutterSecureStorage storage;
  String get _email => '${prefix}_email';
  String get _password => '${prefix}_password';

  @override
  Future<CollegeLogin?> read() async {
    final e = await storage.read(key: _email);
    final p = await storage.read(key: _password);
    return e == null || p == null ? null : (email: e, password: p);
  }

  @override
  Future<void> write(CollegeLogin login) async {
    await storage.write(key: _email, value: login.email.trim());
    await storage.write(key: _password, value: login.password);
  }

  @override
  Future<void> clear() async {
    await storage.delete(key: _email);
    await storage.delete(key: _password);
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
