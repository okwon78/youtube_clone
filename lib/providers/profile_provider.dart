import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/livo_api.dart';
import 'auth_controller.dart';

final livoApiProvider = Provider<LivoApi>((ref) => LivoApi());

/// The signed-in user's profile stats (points, following) fetched from the livo
/// resource server. Re-fetches whenever the access token changes (login/logout/
/// refresh), and auto-disposes when the profile screen is no longer watching it.
final profileStatsProvider = FutureProvider.autoDispose<ProfileStats>((
  ref,
) async {
  final token = ref.watch(authControllerProvider.select((s) => s.token));
  if (token == null) {
    throw LivoApiException('로그인이 필요합니다.');
  }
  return ref.watch(livoApiProvider).fetchProfileStats(token);
});
