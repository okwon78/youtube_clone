import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_api.dart';
import '../services/social_auth.dart';
import '../services/token_storage.dart';

/// Authentication state. A non-null [token] means the user is logged in. The
/// token is persisted via [TokenStorage] so the session survives app restarts.
class AuthState {
  const AuthState({this.token, this.username});

  final String? token;
  final String? username;

  bool get isAuthenticated => token != null;
}

final authApiProvider = Provider<AuthApi>((ref) => AuthApi());

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final socialAuthProvider = Provider<SocialAuth>((ref) => SocialAuth());

/// The auth state restored from storage at startup. Overridden in `main()`
/// once the persisted token has been read, so the app can open directly on
/// the home page without flashing the login screen.
final initialAuthStateProvider = Provider<AuthState>(
  (ref) => const AuthState(),
);

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => ref.read(initialAuthStateProvider);

  AuthApi get _api => ref.read(authApiProvider);
  TokenStorage get _storage => ref.read(tokenStorageProvider);
  SocialAuth get _social => ref.read(socialAuthProvider);

  /// Logs in, stores the issued access token, and persists it. Throws
  /// [AuthApiException] on failure so the UI can surface the message.
  Future<void> login(String username, String password) async {
    final token = await _api.login(username, password);
    await _storage.save(token, username);
    state = AuthState(token: token, username: username);
  }

  /// Registers a new user and then logs them in automatically.
  Future<void> register(String username, String password) async {
    await _api.register(username, password);
    await login(username, password);
  }

  /// Signs in with Google: obtains a Google ID token from the native SDK,
  /// exchanges it for our access token, and persists the session. Throws
  /// [SocialLoginCancelled] if the user dismisses the Google dialog.
  Future<void> loginWithGoogle() async {
    final credential = await _social.signInWithGoogle();
    final token = await _api.loginWithGoogle(credential.token);
    final username = credential.displayName ?? 'Google 사용자';
    await _storage.save(token, username);
    state = AuthState(token: token, username: username);
  }

  /// Signs in with Naver: obtains a Naver access token from the native SDK,
  /// exchanges it for our access token, and persists the session. Throws
  /// [SocialLoginCancelled] if the user dismisses the Naver flow.
  Future<void> loginWithNaver() async {
    final credential = await _social.signInWithNaver();
    final token = await _api.loginWithNaver(credential.token);
    final username = credential.displayName ?? '네이버 사용자';
    await _storage.save(token, username);
    state = AuthState(token: token, username: username);
  }

  /// Clears the in-memory state, the persisted session, and any social
  /// provider session so the next login prompts the account picker again.
  Future<void> logout() async {
    await _social.signOut();
    await _storage.clear();
    state = const AuthState();
  }
}
