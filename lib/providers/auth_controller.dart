import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_api.dart';
import '../services/social_auth.dart';
import '../services/token_storage.dart';

final authApiProvider = Provider<AuthApi>((ref) => AuthApi());

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final socialAuthProvider = Provider<SocialAuth>((ref) => SocialAuth());

/// The auth state restored from storage at startup. Overridden in `main()`
/// once the persisted session has been read, so the app can open directly on
/// the home page without flashing the login screen.
final initialAuthStateProvider = Provider<AuthState>(
  (ref) => const AuthState(),
);

/// Authentication state. A non-null [token] (JWT access token) means the user
/// is logged in. The [refreshToken] obtains a new access token when it expires.
/// Both are persisted via [TokenStorage] so the session survives app restarts.
class AuthState {
  const AuthState({this.token, this.refreshToken, this.username});

  final String? token;
  final String? refreshToken;
  final String? username;

  bool get isAuthenticated => token != null;
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => ref.read(initialAuthStateProvider);

  AuthApi get _api => ref.read(authApiProvider);
  TokenStorage get _storage => ref.read(tokenStorageProvider);
  SocialAuth get _social => ref.read(socialAuthProvider);

  /// Self login with username/password: the server validates the credentials
  /// and returns a JWT pair, which we persist. Throws [AuthApiException] on
  /// failure so the UI can react.
  Future<void> login(String username, String password) async {
    final result = await _api.login(username, password);
    await _completeLogin(result, fallbackName: username);
  }

  /// Registers a new user, then signs them in with the same credentials. The
  /// signup consents the user checked are recorded with the new account
  /// (age14/terms/privacy are required, marketing is optional).
  Future<void> register(
    String username,
    String password, {
    bool agreedAge14 = false,
    bool agreedTerms = false,
    bool agreedPrivacy = false,
    bool agreedMarketing = false,
  }) async {
    await _api.register(
      username,
      password,
      agreedAge14: agreedAge14,
      agreedTerms: agreedTerms,
      agreedPrivacy: agreedPrivacy,
      agreedMarketing: agreedMarketing,
    );
    await login(username, password);
  }

  /// Signs in with Google in one shot: native sign-in followed immediately by
  /// the token exchange. Throws [SocialLoginCancelled] if the user dismisses the
  /// Google dialog. Prefer [signInWithGoogle] + [completeGoogleLogin] when the
  /// UI needs to collect consent between the two steps.
  Future<void> loginWithGoogle() async =>
      completeGoogleLogin(await signInWithGoogle());

  /// Signs in with Naver in one shot. See [loginWithGoogle].
  Future<void> loginWithNaver() async =>
      completeNaverLogin(await signInWithNaver());

  /// Runs Google's native sign-in and returns the obtained credential WITHOUT
  /// establishing a session, so the UI can collect consent before the account
  /// is linked. Throws [SocialLoginCancelled] if the user dismisses the dialog.
  Future<SocialCredential> signInWithGoogle() => _social.signInWithGoogle();

  /// Runs Naver's native sign-in and returns the credential without a session.
  /// See [signInWithGoogle].
  Future<SocialCredential> signInWithNaver() => _social.signInWithNaver();

  /// Exchanges an already-obtained Google [credential] for our JWT pair and
  /// persists the session. Call after the user accepts the required consents.
  Future<void> completeGoogleLogin(SocialCredential credential) =>
      _exchangeSocial(credential, _api.loginWithGoogle, 'Google 사용자');

  /// Exchanges an already-obtained Naver [credential] for our JWT pair and
  /// persists the session. See [completeGoogleLogin].
  Future<void> completeNaverLogin(SocialCredential credential) =>
      _exchangeSocial(credential, _api.loginWithNaver, '네이버 사용자');

  /// Shared tail of the social flow: exchange the provider token for our JWT
  /// pair, then persist the session under the provider's display name.
  Future<void> _exchangeSocial(
    SocialCredential credential,
    Future<AuthResult> Function(String providerToken) exchange,
    String fallbackName,
  ) async {
    final result = await exchange(credential.token);
    await _completeLogin(
      result,
      fallbackName: credential.displayName ?? credential.email ?? fallbackName,
    );
  }

  /// Persists an issued JWT pair + username and flips the in-memory state to
  /// authenticated. Used by every successful login path. The server-provided
  /// username wins; [fallbackName] is used only if it didn't send one.
  Future<void> _completeLogin(
    AuthResult result, {
    required String fallbackName,
  }) async {
    final username = result.username ?? fallbackName;
    await _storage.save(result.accessToken, result.refreshToken, username);
    state = AuthState(
      token: result.accessToken,
      refreshToken: result.refreshToken,
      username: username,
    );
  }

  /// Clears the in-memory state, the persisted session, any social provider
  /// session, and revokes the refresh token server-side so it can't be reused.
  Future<void> logout() async {
    final refreshToken = state.refreshToken;
    if (refreshToken != null) {
      await _api.logout(refreshToken);
    }
    await _social.signOut();
    await _storage.clear();
    state = const AuthState();
  }
}
