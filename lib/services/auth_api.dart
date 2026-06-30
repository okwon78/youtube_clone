import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thrown when the auth server rejects a request. [message] is safe to show
/// directly to the user.
class AuthApiException implements Exception {
  AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// One signup consent item served by the auth server (`GET /consents/signup`).
///
/// The server is the source of truth for the consent list so wording, links,
/// required-ness and ordering can change without an app release. [key] is the
/// stable identifier (survives label changes) used when recording what the user
/// agreed to; [version] tags the wording for the consent audit trail; [required]
/// items must all be checked to proceed; [link] is the full-text URL (empty when
/// there's nothing to open, e.g. the age check).
class ConsentItem {
  const ConsentItem({
    required this.key,
    required this.version,
    required this.required,
    required this.label,
    required this.link,
  });

  final String key;
  final String version;
  final bool required;
  final String label;
  final String link;

  factory ConsentItem.fromJson(Map<String, dynamic> json) => ConsentItem(
    key: (json['key'] ?? '').toString(),
    version: (json['version'] ?? '').toString(),
    required: json['required'] == true,
    label: (json['label'] ?? '').toString(),
    link: (json['link'] ?? '').toString(),
  );

  /// Local fallback used when the server can't be reached, so the signup form
  /// still renders. Mirrors the server's default list; the server's response
  /// takes precedence whenever it's available.
  static const fallback = <ConsentItem>[
    ConsentItem(
      key: 'age14',
      version: '1.0',
      required: true,
      label: '만 14세 이상입니다.',
      link: '',
    ),
    ConsentItem(
      key: 'terms',
      version: '1.0',
      required: true,
      label: '이용약관 동의 (필수)',
      link: 'https://livo.example.com/legal/terms',
    ),
    ConsentItem(
      key: 'privacy',
      version: '1.0',
      required: true,
      label: '개인정보 수집·이용 동의 (필수)',
      link: 'https://livo.example.com/legal/privacy',
    ),
    ConsentItem(
      key: 'marketing',
      version: '1.0',
      required: false,
      label: '광고성 정보 수신 동의 (선택)',
      link: 'https://livo.example.com/legal/marketing',
    ),
  ];
}

/// A successful login/refresh result: the JWT [accessToken], the [refreshToken]
/// used to obtain a new pair when the access token expires, and the owning
/// [username] — the server's display name (`username`: the email local-part +
/// random digits at signup, user-changeable), NOT the email login id. Null only
/// if the server omitted it, in which case the caller falls back to a name it
/// already has.
typedef AuthResult = ({
  String accessToken,
  String refreshToken,
  String? username,
});

/// HTTP client for the **JWT auth server**, reached through the API gateway
/// (port 8080). The gateway forwards these auth/token endpoints to the auth
/// server without an auth_request check (they issue/manage tokens).
///
/// This app uses a self-managed JWT scheme:
///   - Self login: POST email/password to `/login`; the server validates the
///     credentials and returns a JWT access token + a refresh token.
///   - Social login: the native SDK yields a provider credential (Google ID
///     token / Naver access token); the server verifies it and returns the same
///     JWT pair via `/oauth/google` / `/oauth/naver`.
///   - `/auth/refresh` rotates an expiring access token; `/register` creates a
///     user; `/auth/logout` revokes a refresh token.
class AuthApi {
  AuthApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? defaultBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  /// API gateway base URL.
  ///
  /// All traffic now goes through the **Nginx gateway (port 8080)**, the single
  /// entry point. The gateway proxies auth/token endpoints (`/login`, `/oauth/*`,
  /// …) straight to the auth server; the auth server itself is no longer exposed
  /// on the host. Override at build/run time:
  ///   flutter run --dart-define=AUTH_BASE_URL=http://192.168.0.91:8080
  /// Useful values:
  ///   - Android emulator: http://10.0.2.2:8080
  ///   - iOS simulator / desktop: http://localhost:8080
  ///   - Physical device (same WiFi): `http://<dev-machine-LAN-IP>:8080`
  static const defaultBaseUrl = String.fromEnvironment(
    'AUTH_BASE_URL',
    defaultValue: 'http://0.0.0.0:8080',
  );

  static const _jsonHeaders = {'Content-Type': 'application/json'};

  /// Self login: posts email/password to `/login` and returns the issued JWT
  /// pair. Throws [AuthApiException] on bad credentials or failure.
  Future<AuthResult> login(String email, String password) {
    return _requestTokens(
      '/login',
      body: jsonEncode({'email': email, 'password': password}),
      unauthorizedMessage: '아이디 또는 비밀번호가 올바르지 않습니다.',
      failureMessage: '로그인에 실패했습니다.',
    );
  }

  /// Exchanges a refresh token for a fresh JWT pair (the server rotates the
  /// refresh token, so the old one is invalidated). Throws [AuthApiException]
  /// if the refresh token is expired or already used.
  Future<AuthResult> refresh(String refreshToken) {
    return _requestTokens(
      '/auth/refresh',
      body: jsonEncode({'refresh_token': refreshToken}),
      unauthorizedMessage: '세션이 만료되었습니다. 다시 로그인해 주세요.',
      failureMessage: '세션 갱신에 실패했습니다.',
    );
  }

  /// Revokes the refresh token server-side on logout. Best-effort: failures are
  /// swallowed since the client clears its own session regardless.
  Future<void> logout(String refreshToken) async {
    try {
      await _client.post(
        Uri.parse('$_baseUrl/auth/logout'),
        headers: _jsonHeaders,
        body: jsonEncode({'refresh_token': refreshToken}),
      );
    } catch (_) {
      // Network/server error on logout shouldn't block the local sign-out.
    }
  }

  /// Exchanges a Google **ID token** (from `google_sign_in`) for our own JWT
  /// pair via `/oauth/google`. The server verifies the ID token against
  /// Google's public keys and auto-creates the user on first login.
  Future<AuthResult> loginWithGoogle(String idToken) {
    return _requestTokens(
      '/oauth/google',
      body: jsonEncode({'id_token': idToken}),
      unauthorizedMessage: '구글 인증에 실패했습니다. 다시 시도해 주세요.',
      failureMessage: '구글 로그인에 실패했습니다.',
    );
  }

  /// Exchanges a Naver **access token** (from `naver_login_flutter`) for our
  /// own JWT pair via `/oauth/naver`. The server validates the token by calling
  /// Naver's profile API and auto-creates the user on first login.
  Future<AuthResult> loginWithNaver(String naverAccessToken) {
    return _requestTokens(
      '/oauth/naver',
      body: jsonEncode({'access_token': naverAccessToken}),
      unauthorizedMessage: '네이버 인증에 실패했습니다. 다시 시도해 주세요.',
      failureMessage: '네이버 로그인에 실패했습니다.',
    );
  }

  /// POSTs JSON to a token-issuing endpoint and parses the `{access_token,
  /// refresh_token, user_id}` response. Shared by login, refresh, Google and
  /// Naver, which differ only in path, payload, and error copy.
  /// [unauthorizedMessage] is shown for a 401; any other non-200 falls back to
  /// [failureMessage] (or the server's message).
  Future<AuthResult> _requestTokens(
    String path, {
    required Object body,
    required String unauthorizedMessage,
    required String failureMessage,
  }) async {
    final res = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: _jsonHeaders,
      body: body,
    );

    final decoded = _decode(res.body);
    if (res.statusCode == 200) {
      final access = decoded['access_token'];
      final refresh = decoded['refresh_token'];
      if (access is String &&
          access.isNotEmpty &&
          refresh is String &&
          refresh.isNotEmpty) {
        final name = decoded['username'];
        return (
          accessToken: access,
          refreshToken: refresh,
          username: name is String && name.isNotEmpty ? name : null,
        );
      }
      throw AuthApiException('서버 응답에 토큰이 없습니다.');
    }
    if (res.statusCode == 401) throw AuthApiException(unauthorizedMessage);
    throw AuthApiException(_message(decoded, failureMessage));
  }

  /// Requests an email-verification code via `/email/verification`. The server
  /// stores a 6-digit code (Redis, 8-min TTL) and—once SMTP is wired—mails it.
  /// Returns the code's lifetime in seconds (`expires_in`) so the UI can drive
  /// its countdown from the server. Throws [AuthApiException] on failure.
  Future<int> requestEmailVerification(String email) async {
    final res = await _client.post(
      Uri.parse('$_baseUrl/email/verification'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email}),
    );

    final decoded = _decode(res.body);
    if (res.statusCode == 200) {
      final expiresIn = decoded['expires_in'];
      return expiresIn is int ? expiresIn : 0;
    }
    throw AuthApiException(_message(decoded, '인증 메일 발송에 실패했습니다.'));
  }

  /// Confirms an email-verification code via `/email/verification/confirm`. On
  /// success the server consumes the code and marks the email verified (~30 min)
  /// so the following signup can require a verified email. Throws
  /// [AuthApiException] with a user-facing message if the code is wrong/expired.
  Future<void> confirmEmailVerification(String email, String code) async {
    final res = await _client.post(
      Uri.parse('$_baseUrl/email/verification/confirm'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email, 'code': code}),
    );

    if (res.statusCode == 200) return;
    final decoded = _decode(res.body);
    switch (decoded['error']) {
      case 'code_mismatch':
        throw AuthApiException('인증번호가 올바르지 않습니다.');
      case 'code_expired':
        throw AuthApiException('인증 시간이 만료되었어요. 이메일을 재발송해 주세요.');
    }
    throw AuthApiException(_message(decoded, '인증번호 확인에 실패했습니다.'));
  }

  /// Fetches the signup consent items from `GET /consents/signup`. The server
  /// owns the list (wording, links, required-ness, order) so it can change
  /// without an app release. Throws [AuthApiException] on failure so the caller
  /// can fall back to [ConsentItem.fallback].
  Future<List<ConsentItem>> fetchSignupConsents() async {
    final res = await _client.get(Uri.parse('$_baseUrl/consents/signup'));
    final decoded = _decode(res.body);
    if (res.statusCode == 200) {
      final items = decoded['items'];
      if (items is List) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(ConsentItem.fromJson)
            .toList();
      }
      return const [];
    }
    throw AuthApiException(_message(decoded, '동의 항목을 불러오지 못했습니다.'));
  }

  /// Creates a new user. The [email] is the login id and must be email-shaped
  /// (the server rejects non-email ids with 400). The signup consents the user
  /// checked are recorded with the account: [agreedAge14], [agreedTerms] and
  /// [agreedPrivacy] are the required terms, [agreedMarketing] is optional.
  /// Throws [AuthApiException] on failure.
  Future<void> register(
    String email,
    String password, {
    bool agreedAge14 = false,
    bool agreedTerms = false,
    bool agreedPrivacy = false,
    bool agreedMarketing = false,
  }) async {
    final res = await _client.post(
      Uri.parse('$_baseUrl/register'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'email': email,
        'password': password,
        'agreed_age14': agreedAge14,
        'agreed_terms': agreedTerms,
        'agreed_privacy': agreedPrivacy,
        'agreed_marketing': agreedMarketing,
      }),
    );

    if (res.statusCode == 201) return;
    if (res.statusCode == 409) {
      throw AuthApiException('이미 사용 중인 이메일입니다.');
    }
    throw AuthApiException(_message(_decode(res.body), '회원가입에 실패했습니다.'));
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  String _message(Map<String, dynamic> body, String fallback) =>
      (body['message'] ?? body['error'] ?? fallback).toString();
}
