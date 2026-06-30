import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:naver_login_flutter/naver_login_flutter.dart';

/// Thrown when the user backs out of a social sign-in flow. The UI should
/// treat this as a silent no-op rather than showing an error.
class SocialLoginCancelled implements Exception {
  const SocialLoginCancelled();
}

/// The result of a successful social sign-in: the *provider* token that gets
/// handed to our auth server, plus an optional display name and email for the
/// UI (e.g. the social consent screen shown before the account is linked).
class SocialCredential {
  const SocialCredential({required this.token, this.displayName, this.email});

  final String token;
  final String? displayName;
  final String? email;
}

/// Wraps the Google and Naver native SDKs. It only obtains the provider token
/// (Google ID token / Naver access token); exchanging that for our own access
/// token happens server-side via `AuthApi.loginWithGoogle`/`loginWithNaver`.
class SocialAuth {
  /// Caches the one-time Google SDK initialization. The first call kicks off
  /// `initialize()`; every later call awaits the same Future, so it never runs
  /// twice for this instance.
  Future<void>? _googleInit;

  Future<void> _ensureGoogleInitialized() {
    return _googleInit ??= GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId,
    );
  }

  /// The OAuth **web client ID** from the Google Cloud console. It becomes the
  /// audience of the issued ID token, and is REQUIRED on Android for
  /// `authenticate()` to return a non-null `idToken`. Provide it at build time:
  ///
  ///   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '832649409497-c4uhcudkersffsvbsspmhacnt3c8rnfc.apps.googleusercontent.com',
  );

  bool _googleSignIn = false;

  /// Runs the Google sign-in flow and returns a Google **ID token**.
  /// Throws [SocialLoginCancelled] if the user dismisses the dialog.
  Future<SocialCredential> signInWithGoogle() async {
    _googleSignIn = true;
    debugPrint('[google] 1) initialize 시작');
    await _ensureGoogleInitialized();
    debugPrint('[google] 2) initialize 완료, authenticate() 호출');

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception(
          'authenticate() 60초 무응답 — 계정 선택창이 닫힌 뒤 결과가 돌아오지 않음',
        ),
      );
      debugPrint('[google] 3) authenticate() 반환: ${account.email}');
    } on GoogleSignInException catch (e) {
      debugPrint(
        '[google] authenticate() 실패: code=${e.code} desc=${e.description}',
      );
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const SocialLoginCancelled();
      }
      rethrow;
    }

    final idToken = account.authentication.idToken;
    debugPrint(
      '[google] 4) idToken ${idToken == null ? "== null" : "길이 ${idToken.length}"}',
    );
    if (idToken == null || idToken.isEmpty) {
      throw Exception(
        'Google ID 토큰을 받지 못했습니다. GOOGLE_SERVER_CLIENT_ID 설정을 확인하세요.',
      );
    }
    return SocialCredential(
      token: idToken,
      displayName: account.displayName,
      email: account.email,
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
      displayName: account?.nickname ?? account?.name,
      email: account?.email,
    );
  }

  /// Clears the Google/Naver native sessions so the next login prompts again.
  Future<void> signOut() async {
    if (_googleSignIn) {
      await GoogleSignIn.instance.signOut();
    }
    try {
      await FlutterNaverLogin.logOut();
    } catch (_) {
      // Naver may not have an active session; ignore.
    }
  }
}
