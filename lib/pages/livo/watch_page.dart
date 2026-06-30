import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/broadcast.dart';
import '../../providers/auth_controller.dart';
import '../../theme/livo_theme.dart';
import '../../widgets/livo_common.dart';
import 'login_page.dart';

class _ChatLine {
  const _ChatLine(this.user, this.text, this.color);
  final String user;
  final String text;
  final Color color;
}

/// Live viewing screen: video still, streamer/follow row, and a real-time
/// chat. Following and chatting require a signed-in user; otherwise we route
/// to the login screen.
class WatchPage extends ConsumerStatefulWidget {
  const WatchPage({super.key, required this.data});

  final Broadcast data;

  @override
  ConsumerState<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends ConsumerState<WatchPage> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  bool _following = false;

  final List<_ChatLine> _chat = [
    const _ChatLine('별빛러버', '오늘도 방송 켜주셔서 감사해요 ❤', Color(0xFFFF8FB1)),
    const _ChatLine('초코마니아', 'ㅋㅋㅋㅋ 방금 그거 실화냐', Color(0xFF8FD3FF)),
    const _ChatLine('야경수집가', '신청곡 됩니다!', Color(0xFFB6FF9C)),
    const _ChatLine('심야손님', '들어왔습니다~', Color(0xFFC9B6FF)),
  ];

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _loggedIn => ref.read(authControllerProvider).isAuthenticated;

  void _needLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LivoLoginPage(),
        fullscreenDialog: true,
      ),
    );
  }

  void _send() {
    if (!_loggedIn) {
      _needLogin();
      return;
    }
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _chat.add(_ChatLine('나', text, LivoColors.accent));
      _msgController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleFollow() {
    if (!_loggedIn) {
      _needLogin();
      return;
    }
    setState(() => _following = !_following);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final loggedIn = ref.watch(
      authControllerProvider.select((s) => s.isAuthenticated),
    );
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ── Video area ──────────────────────────────────────────────
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: 0.92,
                  child: LivoImage(thumbUrl(data.seed, w: 720, h: 450)),
                ),
                Positioned(
                  top: topInset + 8,
                  left: 12,
                  child: _RoundIconButton(
                    icon: Icons.chevron_left,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Positioned(
                  top: topInset + 8,
                  right: 12,
                  child: Row(
                    children: [
                      const LiveBadge(),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x80000000),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '👁 ${fmtViewers(data.viewers)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Stack(
                    children: [
                      Container(height: 3, color: const Color(0x26FFFFFF)),
                      FractionallySizedBox(
                        widthFactor: 0.7,
                        child: Container(height: 3, color: LivoColors.live),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Streamer row ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: LivoColors.bg,
              border: Border(bottom: BorderSide(color: LivoColors.line)),
            ),
            child: Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: LivoImage(avatarUrl(data.seed)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.streamer,
                        style: const TextStyle(
                          color: LivoColors.text,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: LivoColors.sub,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: _following ? LivoColors.surface2 : LivoColors.live,
                  shape: const StadiumBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _toggleFollow,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9,
                      ),
                      child: Text(
                        _following ? '팔로잉' : '팔로우',
                        style: TextStyle(
                          color: _following ? LivoColors.sub : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Chat list ───────────────────────────────────────────────
          Expanded(
            child: Container(
              color: Colors.black,
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: _chat.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return const Center(
                      child: Text(
                        '실시간 채팅에 입장하셨습니다!',
                        style: TextStyle(
                          color: LivoColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }
                  final m = _chat[i - 1];
                  return RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, height: 1.4),
                      children: [
                        TextSpan(
                          text: '${m.user}  ',
                          style: TextStyle(
                            color: m.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: m.text,
                          style: const TextStyle(color: Color(0xFFE6E6EA)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Chat input ──────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(14, 10, 14, bottomInset + 10),
            decoration: const BoxDecoration(
              color: LivoColors.bg,
              border: Border(top: BorderSide(color: LivoColors.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    onTap: loggedIn ? null : _needLogin,
                    readOnly: !loggedIn,
                    onSubmitted: (_) => _send(),
                    cursorColor: LivoColors.accent,
                    style: const TextStyle(
                      color: LivoColors.text,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: LivoColors.surface,
                      hintText: loggedIn ? '채팅을 입력해 주세요' : '로그인 후 채팅할 수 있어요',
                      hintStyle: const TextStyle(
                        color: LivoColors.faint,
                        fontSize: 14,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9999),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: LivoColors.accent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _send,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x66000000),
      shape: const CircleBorder(side: BorderSide(color: Color(0x33FFFFFF))),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
