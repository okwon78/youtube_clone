import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the access token and username in the platform secure store
/// (Keychain on iOS, EncryptedSharedPreferences on Android) so the login
/// session survives app restarts.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'access_token';
  static const _usernameKey = 'username';

  /// Saves the issued token and the username it belongs to.
  Future<void> save(String token, String username) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _usernameKey, value: username);
  }

  /// Reads the saved token, or null if the user has never logged in.
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  /// Reads the saved username, or null if none was stored.
  Future<String?> readUsername() => _storage.read(key: _usernameKey);

  /// Clears the saved session on logout.
  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _usernameKey);
  }
}
