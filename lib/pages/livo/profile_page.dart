import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/broadcast.dart';
import '../../providers/auth_controller.dart';
import '../../providers/profile_provider.dart';
import '../../theme/livo_theme.dart';
import '../../widgets/livo_common.dart';

/// MY tab (signed in): avatar, stats, point-charge CTA, activity/settings menus
/// and a logout action wired to the real [AuthController].
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = ref.watch(
      authControllerProvider.select((s) => s.username),
    );
    final nick = username ?? 'livo_user';
    final stats = ref.watch(profileStatsProvider);
    final topInset = MediaQuery.of(context).padding.top;

    return RefreshIndicator(
      // 포인트는 외부에서 바뀔 수 있으므로, 당겨서 livo 서버 통계를 다시 받아온다.
      onRefresh: () => ref.refresh(profileStatsProvider.future),
      color: LivoColors.accent,
      child: ListView(
        // 내용이 짧아도 항상 당겨서 새로고침이 동작하도록 한다.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          SizedBox(height: topInset + 12),
          // ── Identity row ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: LivoColors.accent, width: 2),
                  ),
                  child: ClipOval(child: LivoImage(meAvatarUrl(username))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nick,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: LivoColors.text,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'LIVO 계정 연결됨',
                        style: TextStyle(color: LivoColors.sub, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
                _SquareIconButton(
                  icon: Icons.settings_outlined,
                  onTap: () => _comingSoon(context),
                ),
              ],
            ),
          ),

          // ── Stats card ────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(18, 0, 18, 22),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: LivoColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: '팔로잉',
                    value: stats.whenOrNull(
                      data: (s) => _formatNumber(s.following),
                    ),
                    first: true,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: '포인트',
                    value: stats.whenOrNull(
                      data: (s) => _formatNumber(s.points),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Charge CTA ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: PillButton(
              full: true,
              height: 48,
              onPressed: () => _comingSoon(context),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monetization_on_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('포인트 충전하기'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          const _MenuLabel('내 활동'),
          _MenuRow(
            icon: Icons.access_time,
            label: '시청 기록',
            onTap: () => _comingSoon(context),
          ),
          _MenuRow(
            icon: Icons.favorite_border,
            label: '팔로우 목록',
            last: true,
            onTap: () => _comingSoon(context),
          ),
          const _MenuLabel('설정'),
          _MenuRow(
            icon: Icons.notifications_none,
            label: '알림 설정',
            onTap: () => _comingSoon(context),
          ),
          _MenuRow(
            icon: Icons.person_outline,
            label: '계정 설정',
            last: true,
            onTap: () => _comingSoon(context),
          ),

          // ── Logout ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 30),
            child: OutlinedButton.icon(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).logout(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                foregroundColor: LivoColors.sub,
                side: const BorderSide(color: LivoColors.line, width: 1.5),
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.logout, size: 19),
              label: const Text(
                '로그아웃',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('준비 중이에요')));
  }
}

/// Formats an integer with thousands separators (e.g. 8400 → "8,400") without
/// pulling in `intl`.
String _formatNumber(int n) {
  final digits = n.abs().toString();
  final buf = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return buf.toString();
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.first = false});

  final String label;

  /// The stat value, or null while it's still loading from the resource server
  /// (or if the fetch failed), in which case a placeholder is shown.
  final String? value;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: first
          ? null
          : const BoxDecoration(
              border: Border(left: BorderSide(color: LivoColors.line)),
            ),
      child: Column(
        children: [
          Text(
            value ?? '–',
            style: const TextStyle(
              color: LivoColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: LivoColors.sub, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      child: Text(
        text,
        style: const TextStyle(
          color: LivoColors.faint,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(
                  bottom: BorderSide(color: LivoColors.line, width: 0.5),
                ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 21, color: LivoColors.sub),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: LivoColors.text,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: LivoColors.faint),
          ],
        ),
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: LivoColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 19, color: LivoColors.text),
        ),
      ),
    );
  }
}
