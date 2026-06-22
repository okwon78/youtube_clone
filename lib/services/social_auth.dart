import 'package:google_sign_in/google_sign_in.dart';
import 'package:naver_login_flutter/naver_login_flutter.dart';

/// Thrown when the user backs out of a social sign-in flow. The UI should
/// treat this as a silent no-op rather than showing an error.
class SocialLoginCancelled implements Exception {
  const SocialLoginCancelled();
}

/// The result of a successful social sign-in: the *provider* token that gets
/// handed to our auth server, plus an optional display name for the UI.
class SocialCredential {
  const SocialCredential({required this.token, this.displayName});

  final String token;
  final String? displayName;
}

/// Wraps the Google and Naver native SDKs. It only obtains the provider token
/// (Google ID token / Naver access token); exchanging that for our own access
/// token happens server-side via `AuthApi.loginWithGoogle`/`loginWithNaver`.
class SocialAuth {
  /// The OAuth **web client ID** from the Google Cloud console. It becomes the
  /// audience of the issued ID token, and is REQUIRED on Android for
  /// `authenticate()` to return a non-null `idToken`. Provide it at build time:
  ///
  ///   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId.isEmpty
          ? null
          : _googleServerClientId,
    );
    _googleInitialized = true;
  }

  /// Runs the Google sign-in flow and returns a Google **ID token**.
  /// Throws [SocialLoginCancelled] if the user dismisses the dialog.
  Future<SocialCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const SocialLoginCancelled();
      }
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception(
        'Google ID 토큰을 받지 못했습니다. GOOGLE_SERVER_CLIENT_ID 설정을 확인하세요.',
      );
    }
    return SocialCredential(
      token: idToken,
      displayName: account.displayName ?? account.email,
    );
  }

  /// Runs the Naver sign-in flow and returns a Naver **access token**.
  /// Throws [SocialLoginCancelled] if the user dismisses the flow.
  Future<SocialCredential> signInWithNaver() async {
    final NaverLoginResult result = await FlutterNaverLogin.logIn();
    switch (result.status) {
      case NaverLoginStatus.loggedIn:
        break;
      case NaverLoginStatus.loggedOut:
        throw const SocialLoginCancelled();
      case NaverLoginStatus.error:
        throw Exception('네이버 로그인에 실패했습니다.');
    }

    // Unlike flutter_naver_login, the access token isn't on the login result;
    // it has to be fetched separately after a successful sign-in.
    final NaverToken token = await FlutterNaverLogin.getCurrentAccessToken();
    final accessToken = token.accessToken;
    if (accessToken.isEmpty) throw const SocialLoginCancelled();

    final account = result.account;
    return SocialCredential(
      token: accessToken,
      displayName: account?.email ?? account?.name ?? account?.nickname,
    );
  }

  /// Clears the Google/Naver native sessions so the next login prompts again.
  Future<void> signOut() async {
    if (_googleInitialized) {
      await GoogleSignIn.instance.signOut();
    }
    try {
      await FlutterNaverLogin.logOut();
    } catch (_) {
      // Naver may not have an active session; ignore.
    }
  }
}
