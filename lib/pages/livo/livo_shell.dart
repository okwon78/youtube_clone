import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/broadcast.dart';
import '../../providers/auth_controller.dart';
import '../../providers/profile_provider.dart';
import '../../theme/livo_theme.dart';
import '../../widgets/livo_bottom_nav.dart';
import 'content_pages.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'watch_page.dart';

/// Root of the LIVO app: a 4-tab shell (홈/탐색/랭킹/MY). Content tabs are
/// browseable without an account; selecting MY (or following/chatting in a
/// broadcast) routes through login. Auth state comes from the real
/// [authControllerProvider].
class LivoShell extends ConsumerStatefulWidget {
  const LivoShell({super.key});

  @override
  ConsumerState<LivoShell> createState() => _LivoShellState();
}

class _LivoShellState extends ConsumerState<LivoShell> {
  /// Index of the MY tab (last tab), which requires authentication.
  static const _myTab = 3;

  int _index = 0;

  void _openWatch(Broadcast data) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => WatchPage(data: data)));
  }

  void _search() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('검색은 준비 중이에요')));
  }

  void _toast(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openLogin() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const LivoLoginPage(),
        fullscreenDialog: true,
      ),
    );
    if (!mounted) return;

    if (ok == true && ref.read(authControllerProvider).isAuthenticated) {
      setState(() => _index = _myTab);
      _toast('LIVO에 오신 걸 환영해요 🎉');
    }
  }

  void _onSelectTab(int i) {
    if (i == _myTab && !ref.read(authControllerProvider).isAuthenticated) {
      _openLogin();
      return;
    }
    // IndexedStack 은 MY 탭을 계속 살려두므로, 다른 탭에서 MY 로 (재)진입할 때
    // 프로필 통계를 무효화해 livo 서버에서 최신 포인트/팔로잉을 다시 받아온다.
    if (i == _myTab && _index != _myTab) {
      ref.invalidate(profileStatsProvider);
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(
      authControllerProvider.select((s) => s.isAuthenticated),
    );
    final username = ref.watch(
      authControllerProvider.select((s) => s.username),
    );

    // If the user logs out while on the MY tab, fall back to Home.
    ref.listen(authControllerProvider.select((s) => s.isAuthenticated), (
      previous,
      next,
    ) {
      if (!next && _index == _myTab) setState(() => _index = 0);
    });

    final pages = [
      HomeScreen(onOpen: _openWatch, onSearch: _search),
      ExploreScreen(onOpen: _openWatch, onSearch: _search),
      RankingScreen(onSearch: _search),
      loggedIn ? const ProfileScreen() : const SizedBox.shrink(),
    ];

    return Scaffold(
      backgroundColor: LivoColors.bg,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: LivoBottomNav(
        active: _index,
        onSelect: _onSelectTab,
        avatarUrl: loggedIn ? meAvatarUrl(username) : null,
      ),
    );
  }
}
