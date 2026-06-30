import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The persisted session: JWT access token, refresh token, and the owning
/// username. Stored together so a login survives app restarts.
typedef StoredSession = ({
  String accessToken,
  String refreshToken,
  String? username,
});

/// Persists the JWT access token, refresh token, and username in the platform
/// secure store (Keychain on iOS, EncryptedSharedPreferences on Android) so the
/// login session survives app restarts.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _usernameKey = 'username';

  /// Saves the issued token pair and the username they belong to.
  Future<void> save(
    String accessToken,
    String refreshToken,
    String username,
  ) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _usernameKey, value: username);
  }

  /// Reads the saved session, or null if the user has never logged in (no
  /// access or refresh token stored).
  Future<StoredSession?> read() async {
    final access = await _storage.read(key: _accessTokenKey);
    final refresh = await _storage.read(key: _refreshTokenKey);
    if (access == null || refresh == null) return null;
    final username = await _storage.read(key: _usernameKey);
    return (accessToken: access, refreshToken: refresh, username: username);
  }

  /// Clears the saved session on logout.
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _usernameKey);
  }
}
