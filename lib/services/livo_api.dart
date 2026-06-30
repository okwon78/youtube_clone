import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thrown when the livo resource server rejects a request. [message] is safe to
/// show directly to the user.
class LivoApiException implements Exception {
  LivoApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The signed-in user's profile stats served by the livo resource server:
/// [points] (보유 포인트) and [following] (팔로잉 수).
typedef ProfileStats = ({int points, int following});

/// HTTP client for the **livo resource server**, reached through the API
/// gateway (port 8080).
///
/// This server doesn't issue tokens — it serves resources protected behind the
/// gateway. We still send the JWT access token as a Bearer header; the **Nginx
/// gateway** validates it via an auth_request subrequest to the auth server and,
/// on success, forwards the owner's user_id to livo (which scopes the response
/// to it). So each user only sees their own resources, but livo itself never
/// checks the token — the gateway does.
class LivoApi {
  LivoApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? defaultBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  /// API gateway base URL.
  ///
  /// Same Nginx gateway (port 8080) as [AuthApi.defaultBaseUrl] — the single
  /// entry point for both auth and resource traffic. Override at run time:
  ///   flutter run --dart-define=LIVO_BASE_URL=http://192.168.0.91:8080
  ///   - Android emulator: http://10.0.2.2:8080
  ///   - iOS simulator / desktop: http://localhost:8080
  ///   - Physical device (same WiFi): `http://<dev-machine-LAN-IP>:8080`
  static const defaultBaseUrl = String.fromEnvironment(
    'LIVO_BASE_URL',
    defaultValue: 'http://0.0.0.0:8080',
  );

  /// Fetches the signed-in user's profile stats from `GET /me/stats`.
  /// [accessToken] is the JWT access token sent as `Authorization: Bearer ...`.
  /// Throws [LivoApiException] on an expired/invalid token or other failure.
  Future<ProfileStats> fetchProfileStats(String accessToken) async {
    final res = await _client.get(
      Uri.parse('$_baseUrl/me/stats'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        final points = decoded['points'];
        final following = decoded['following'];
        return (
          points: points is int ? points : 0,
          following: following is int ? following : 0,
        );
      }
      throw LivoApiException('프로필 정보를 불러오지 못했습니다.');
    }
    if (res.statusCode == 401) {
      throw LivoApiException('세션이 만료되었습니다. 다시 로그인해 주세요.');
    }
    throw LivoApiException('프로필 정보를 불러오지 못했습니다.');
  }
}
