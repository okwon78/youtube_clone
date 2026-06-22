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

/// HTTP client for the OAuth2 authorization server (port 8081).
///
/// It uses the OAuth2 *password grant* to turn a username/password into an
/// access token, and the `/register` endpoint to create new users.
class AuthApi {
  AuthApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? defaultBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  /// Auth server base URL. On the Android emulator the host machine is reached
  /// via `http://10.0.2.2:8081` instead of `localhost`.
  static const defaultBaseUrl = 'http://localhost:8081';

  // Learning-only test client registered by the server seed data.
  static const _clientId = 'client1';
  static const _clientSecret = 'secret';

  /// Logs in via the password grant and returns the access token.
  Future<String> login(String username, String password) async {
    final res = await _client.post(
      Uri.parse('$_baseUrl/oauth/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'password',
        'username': username,
        'password': password,
        'client_id': _clientId,
        'client_secret': _clientSecret,
      },
    );

    final body = _decode(res.body);
    if (res.statusCode == 200) return _extractToken(body);
    if (res.statusCode == 401) {
      throw AuthApiException('아이디 또는 비밀번호가 올바르지 않습니다.');
    }
    throw AuthApiException(_message(body, '로그인에 실패했습니다.'));
  }

  /// Exchanges a Google **ID token** (from `google_sign_in`) for our own
  /// access token via the auth server's `/oauth/google` endpoint. The server
  /// verifies the ID token against Google's public keys and auto-creates the
  /// user on first login.
  Future<String> loginWithGoogle(String idToken) async {
    final res = await _client.post(
      Uri.parse('$_baseUrl/oauth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': idToken, 'client_id': _clientId}),
    );

    final body = _decode(res.body);
    if (res.statusCode == 200) return _extractToken(body);
    if (res.statusCode == 401) {
      throw AuthApiException('구글 인증에 실패했습니다. 다시 시도해 주세요.');
    }
    throw AuthApiException(_message(body, '구글 로그인에 실패했습니다.'));
  }

  /// Exchanges a Naver **access token** (from `naver_login_flutter`) for our
  /// own access token via the auth server's `/oauth/naver` endpoint. The
  /// server validates the token by calling Naver's profile API and
  /// auto-creates the user on first login.
  Future<String> loginWithNaver(String naverAccessToken) async {
    final res = await _client.post(
      Uri.parse('$_baseUrl/oauth/naver'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'access_token': naverAccessToken,
        'client_id': _clientId,
      }),
    );

    final body = _decode(res.body);
    if (res.statusCode == 200) return _extractToken(body);
    if (res.statusCode == 401) {
      throw AuthApiException('네이버 인증에 실패했습니다. 다시 시도해 주세요.');
    }
    throw AuthApiException(_message(body, '네이버 로그인에 실패했습니다.'));
  }

  /// Pulls the `access_token` out of a successful token response.
  String _extractToken(Map<String, dynamic> body) {
    final token = body['access_token'];
    if (token is String && token.isNotEmpty) return token;
    throw AuthApiException('서버 응답에 access_token이 없습니다.');
  }

  /// Creates a new user. Throws [AuthApiException] on failure.
  Future<void> register(String username, String password) async {
    final res = await _client.post(
      Uri.parse('$_baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (res.statusCode == 201) return;
    if (res.statusCode == 409) {
      throw AuthApiException('이미 사용 중인 사용자명입니다.');
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
